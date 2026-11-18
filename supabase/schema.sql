-- Luka's Letter to Santa: database setup for Supabase.
-- Run this whole file once in Supabase: SQL Editor > New query > paste > Run.
--
-- How it is protected:
--   * The table cannot be read or written directly from the web page.
--   * The page can only call the three functions below.
--   * Family members only learn WHICH gifts are reserved and whether a
--     reservation is theirs. Names and secret codes never leave the database.
--   * Parents see who reserved what in Supabase: Table Editor > reservations.

create table if not exists public.reservations (
  gift_id     text primary key,                 -- one reservation per gift: stops double booking
  member_id   text not null,                    -- who reserved it (parents read it in the Table Editor)
  owner_code  text not null,                    -- secret code made by the family member's device
  reserved_at timestamptz not null default now()
);

-- No policies on purpose: with row level security on and no policy, the web page
-- cannot touch the table directly. Only the security definer functions can.
alter table public.reservations enable row level security;
revoke all on public.reservations from anon, authenticated;

-- A reservation counts as "mine" when the device code matches OR the chosen name matches.
-- (Messenger's built-in browser forgets the device code, so the name is the fallback.)
drop function if exists public.list_reservations(text);
drop function if exists public.release_gift(text, text);

create or replace function public.list_reservations(p_owner text, p_member text default '')
returns table (gift_id text, mine boolean)
language sql security definer set search_path = public as $$
  select r.gift_id,
         (r.owner_code = coalesce(p_owner, '') or (coalesce(p_member, '') <> '' and r.member_id = p_member)) as mine
  from public.reservations r;
$$;

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
  return found;   -- true when inserted, false when the gift was already taken
end;
$$;

create or replace function public.release_gift(p_gift text, p_owner text, p_member text default '')
returns text
language plpgsql security definer set search_path = public as $$
begin
  delete from public.reservations
  where gift_id = p_gift
    and (owner_code = coalesce(p_owner, '') or (coalesce(p_member, '') <> '' and member_id = p_member));
  if found then return 'ok'; end if;
  if exists (select 1 from public.reservations where gift_id = p_gift) then return 'not_owner'; end if;
  return 'ok';   -- nothing to cancel
end;
$$;

revoke execute on all functions in schema public from public, anon, authenticated;
grant execute on function public.list_reservations(text, text)  to anon;
grant execute on function public.reserve_gift(text, text, text) to anon;
grant execute on function public.release_gift(text, text, text) to anon;
