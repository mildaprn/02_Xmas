# Setup: put Luka's letter online for the family

The website is in `site/`. It needs two free services: **Supabase** (stores the reservations) and a place to host the page (steps below use **Netlify**). You need to do the account steps yourself, because they need your email and password.

Total time: about 20 minutes.

## 1. Create the database (Supabase)

1. Go to [supabase.com](https://supabase.com) and create a free account.
2. Click **New project**. Name it `luka-xmas`, choose a database password (save it somewhere safe) and a region close to Lithuania (for example Frankfurt).
3. Wait until the project is ready (about 2 minutes).
4. Open **SQL Editor** > **New query**. Paste the whole contents of `supabase/schema.sql` and click **Run**. You should see "Success".

## 2. Set the parents' password

In the SQL Editor, run this with your own password instead of `CHANGE-ME` (write it down, it cannot be read back):

```sql
update public.app_settings
set admin_hash = extensions.crypt('CHANGE-ME', extensions.gen_salt('bf'))
where id = 1;
```

This is the password for the parents' page. It is stored scrambled (hashed) in the database.

## 3. Connect the website to the database

1. In Supabase, open **Project Settings** > **API** (or **API Keys**).
2. Copy the **Project URL** and the public key (called `anon` or `publishable`). Never copy the `service_role` or `secret` key.
3. In `site/`, copy `config.example.js` to `config.js` and paste the two values in.

## 4. Try it on your computer first

Open `site/index.html` in your browser. Check that the letter and the wish list load. With `config.js` filled in, reservations now go to the real database.

## 5. Publish the page (Netlify)

1. Go to [netlify.com](https://www.netlify.com) and create a free account.
2. Choose **Add new site** > **Deploy manually**, and drag the whole `site` folder onto the page. Make sure `config.js` is inside that folder.
3. Netlify gives you a web address like `https://random-name-123.netlify.app`. In **Site configuration** you can change the name to something hard to guess.

## 6. Test before you tell the family

1. Open `https://YOUR-ADDRESS.netlify.app/#tevai` and sign in with your password.
2. Switch **Bandymo režimas** (test mode) **on**.
3. On two different phones, pick different names and reserve gifts. Try to reserve the same gift on both phones at the same moment.
4. Check on the parents' page that the right names show for the right gifts, and that only the person who reserved a gift can cancel it.
5. Switch test mode **off**, and clear the test reservations with **Išvalyti**.

## 7. Send the link to the family

Send `https://YOUR-ADDRESS.netlify.app` (without `#tevai`). The parents' page is only reachable if you know to add `#tevai`, and it needs your password.

## Good to know

- Reservations update on screen every 5 seconds, and straight after someone reserves.
- A family member who reserves a gift on one phone cannot cancel it from another phone. You can clear it for them on the parents' page.
- To change gifts, names or the letter text, edit `site/index.html` (the lists at the top of the script) and drag the folder onto Netlify again.
