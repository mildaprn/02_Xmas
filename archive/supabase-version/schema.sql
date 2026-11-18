-- Luka's Letter to Santa: database setup for Supabase.
-- Run this whole file once in Supabase: SQL Editor > New query > paste > Run.
--
-- How it is protected:
--   * The two tables cannot be read or written directly from the web page.
--   * The page can only call the functions below.
--   * Family members only ever learn WHICH gifts are reserved and whether a
--     reservation is theirs. Names and secret codes never leave the database,
--     except for the parents' page, which needs the parents' password.

create extension if not exists pgcrypto with schema extensions;

-- 1. Tables ------------------------------------------------------------------

create table if not exists public.reservations (
  gift_id     text primary key,                 -- one reservation per gift: stops double booking
  member_id   text not null,                    -- who reserved it (only shown to parents in test mode)
  owner_code  text not null,                    -- secret code made by the family member's device
  reserved_at timestamptz not null default now()
);

create table if not exists public.app_settings (
  id          int primary key default 1 check (id = 1),   -- exactly one row
  test_mode   boolean not null default false,             -- true: parents see who reserved what
  admin_hash  text                                        -- the parents' password, stored hashed
);
insert into public.app_settings (id) values (1) on conflict (id) do nothing;

-- No policies on purpose: with row level security on and no policy, nobody can
-- touch the tables directly. Only the security definer functions below can.
alter table public.reservations enable row level security;
alter table public.app_settings enable row level security;
revoke all on public.reservations from anon, authenticated;
revoke all on public.app_settings from anon, authenticated;

-- 2. Functions for family members ---------------------------------------------

-- Which gifts are reserved, and is the reservation mine (same secret code)?
create or replace function public.list_reservations(p_owner text)
returns table (gift_id text, mine boolean)
language sql security definer set search_path = public as $$
  select r.gift_id, (r.owner_code = coalesce(p_owner, '')) as mine
  from public.reservations r;
$$;

-- Reserve a gift. Returns true if it worked, false if somebody was faster.
create or replace function public.reserve_gift(p_gift text, p_member text, p_owner text)
returns boolean
language plpgsql security definer set search_path = public as $$
begin
  if p_gift !~ '^[a-z0-9_-]{1,40}$' or p_member !~ '^[a-z0-9_-]{1,40}$' or length(coalesce(p_owner, '')) < 16 or length(p_owner) > 80 then
    raise exception 'bad_request';
  end if;
  insert into public.reservations (gift_id, member_id, owner_code)
  values (p_gift, p_member, p_owner)
  on conflict (gift_id) do nothing;
  return found;   -- true when the row was inserted, false when the gift was already taken
end;
$$;

-- Cancel a reservation. Only the device that made it can do this.
create or replace function public.release_gift(p_gift text, p_owner text)
returns text
language plpgsql security definer set search_path = public as $$
begin
  delete from public.reservations where gift_id = p_gift and owner_code = coalesce(p_owner, '');
  if found then return 'ok'; end if;
  if exists (select 1 from public.reservations where gift_id = p_gift) then return 'not_owner'; end if;
  return 'ok';   -- nothing to cancel
end;
$$;

-- 3. Functions for the parents' page (password needed) --------------------------

create or replace function public._admin_ok(p_pass text)
returns boolean
language plpgsql security definer set search_path = public, extensions as $$
declare ok boolean;
begin
  select (admin_hash is not null and admin_hash = crypt(coalesce(p_pass, ''), admin_hash))
    into ok from public.app_settings where id = 1;
  if not coalesce(ok, false) then
    perform pg_sleep(1);          -- slows down password guessing
    return false;
  end if;
  return true;
end;
$$;

create or replace function public.admin_state(p_pass text)
returns json
language plpgsql security definer set search_path = public as $$
declare t boolean;
begin
  if not public._admin_ok(p_pass) then raise exception 'unauthorized'; end if;
  select test_mode into t from public.app_settings where id = 1;
  return json_build_object(
    'test_mode', t,
    'reservations', coalesce((
      select json_agg(json_build_object('gift_id', r.gift_id, 'member_id', case when t then r.member_id else null end) order by r.reserved_at)
      from public.reservations r), '[]'::json)
  );
end;
$$;

create or replace function public.admin_clear(p_pass text, p_gift text)
returns void
language plpgsql security definer set search_path = public as $$
begin
  if not public._admin_ok(p_pass) then raise exception 'unauthorized'; end if;
  delete from public.reservations where gift_id = p_gift;
end;
$$;

create or replace function public.admin_set_test_mode(p_pass text, p_on boolean)
returns void
language plpgsql security definer set search_path = public as $$
begin
  if not public._admin_ok(p_pass) then raise exception 'unauthorized'; end if;
  update public.app_settings set test_mode = coalesce(p_on, false) where id = 1;
end;
$$;

-- 4. Who may call what ----------------------------------------------------------

revoke execute on all functions in schema public from public, anon, authenticated;
grant execute on function public.list_reservations(text)           to anon;
grant execute on function public.reserve_gift(text, text, text)    to anon;
grant execute on function public.release_gift(text, text)          to anon;
grant execute on function public.admin_state(text)                 to anon;
grant execute on function public.admin_clear(text, text)           to anon;
grant execute on function public.admin_set_test_mode(text, boolean) to anon;
-- _admin_ok is internal: the page cannot call it.

-- 5. Set the parents' password (run this separately, with your own password) -----
-- Replace CHANGE-ME with a password of your own, then run just this line:
--
--   update public.app_settings
--   set admin_hash = extensions.crypt('CHANGE-ME', extensions.gen_salt('bf'))
--   where id = 1;
