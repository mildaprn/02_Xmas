# Setup: put Luka's letter online for the family

The website is in `site/`. It needs two free services: **Supabase** (stores the reservations) and a place to host the page (**Netlify**). There is no login inside the app. Parents see who reserved what in the Supabase dashboard, with their own Supabase account.

Total time: about 20 minutes.

## 1. Create the database (Supabase)

1. Go to [supabase.com](https://supabase.com) and create a free account.
2. Click **New project**. Name it `luka-xmas`, choose a database password (save it) and a region close to Lithuania (for example Frankfurt).
3. Wait about 2 minutes until the project is ready.
4. Open **SQL Editor** > **New query**. Paste the whole contents of `supabase/schema.sql` and click **Run**. You should see "Success".

## 2. Connect the website to the database

1. In Supabase, open **Project Settings** > **API** (or **API Keys**).
2. Copy the **Project URL** and the public key (called `anon` or `publishable`). Never copy the `service_role` or `secret` key.
3. In `site/`, copy `config.example.js` to `config.js` and paste in the two values. (Or paste them to Claude and it will write the file.)

## 3. Try it on your computer first

Open `site/index.html` in your browser, open the wish list, pick a name and reserve a gift. In Supabase, open **Table Editor** > **reservations**: you should see a row with the gift and the name. Cancel on the page and the row disappears.

## 4. Publish the page (Netlify)

1. Go to [netlify.com](https://www.netlify.com) and create a free account.
2. Choose **Add new site** > **Deploy manually**, and drag the whole `site` folder onto the page. Make sure `config.js` is inside it.
3. Netlify gives you an address like `https://random-name-123.netlify.app`. In **Site configuration** you can rename it to something hard to guess.

## 5. Test before you tell the family

1. On two phones, open the address, pick different names and reserve gifts. Try the same gift on both phones at once. Only one should win.
2. In the Table Editor, check that the names match the gifts.
3. Check that cancelling works from the same name, also when the link is opened inside Messenger.
4. Delete the test rows in the Table Editor (select them, then delete).

## 6. Send the link to the family

Send the Netlify address. Family members see only "Rezervuota". Do not share your Supabase login.

## Good to know

- Reservations update on screen every 5 seconds and straight after someone reserves.
- A reservation is cancelled by picking the same name that reserved it (or from the same browser). Anyone could cancel another person's gift by picking their name; the risk is accepted for a family list. Delete the row in the Table Editor if needed.
- To change gifts, names or the letter text, edit `site/index.html` (the lists at the top of the script) and drag the folder onto Netlify again.
- Free Supabase projects pause after a week of no use. Open the dashboard and click restore if that happens.
