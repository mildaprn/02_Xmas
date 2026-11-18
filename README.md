# 02 · Xmas

> Part of the **Building with AI** course at Turing College. [← Back to all projects](../README.md)

| | |
|---|---|
| **Type** | App |
| **Status** | Deployed on Netlify; tested with the family's phones |
| **Tools** | Claude Code, HTML/CSS/JavaScript, Supabase (reservations), Netlify (hosting) |

## Problem / goal

Our daughter Luka is 18 months old and her family wants to buy her Christmas presents. Without coordination she could get ten of the same toy. The goal is one simple link where family can read a fun letter from Luka to Santa, see her wish list, and reserve a gift so everyone else sees it is taken.

## What I built

A small web app in Lithuanian with two parts: a handwritten-style letter from Luka to Santa, and an interactive wish list with photos, shop links and a "Reserve" button. Reservations are shared, so every family member sees the same up-to-date list. The app has no login. Parents see who reserved what in the Supabase Table Editor.

- `site/`: the real website (deploy this folder).
- `supabase/schema.sql`: the database setup (one table and three functions).
- `SETUP.md`: step-by-step setup, written for non-programmers.
- `archive/`: earlier variants kept for reference (Supabase with a parents' password page, and a Google Sheet version).
- `app/`: the earlier clickable prototype that runs as a Claude Artifact. Kept for reference.
- `App design/`: the project description and the design document.
- `dovanos/`: the original gift photos. Web-sized copies are in `site/img/`.

## How it works

- Family members open one link, read the letter, open the wish list, pick their name from a list and reserve a gift.
- A gift can have only one reservation. The database allows one row per gift, so two people tapping at the same moment cannot both win.
- A reservation can be cancelled by a device with the matching secret code, or by picking the same name that reserved it. The name fallback exists because Messenger's built-in browser forgets the device code.
- Family members only see "Rezervuota" (reserved). The database never sends names or secret codes to the website.
- The page asks the database for the list every 5 seconds and right after any change.
- Parents open the Supabase Table Editor to see who reserved what, and delete a row to clear a reservation.
- A round moon/sun button in the top-right corner switches between light and dark mode. On the first visit the page follows the phone's setting; after that it remembers the choice in that browser (`localStorage` key `luka_theme`).

```
Family phone → website (site/) → Supabase functions → table "reservations"
Parents → Supabase Table Editor → names, clear a row
```

## How to run

Full steps are in [`SETUP.md`](SETUP.md). In short:

1. Create a Supabase project and run `supabase/schema.sql` in its SQL Editor.
2. Copy `site/config.example.js` to `site/config.js` and paste in the project URL and public key. `config.js` is git-ignored.
3. Drag the `site/` folder onto Netlify to get a private web address.

Without `config.js`, `site/index.html` runs in demo mode: reservations are saved in that one browser only.

Pages: the letter, and the wish list at `#sarasas`.

## How AI was used

- Claude Code wrote the design, the app, the database functions and the setup guide, working from my decisions (language, look, who sees what, how un-reserve works).
- I supplied the letter text, the gift list, the photos and the shop links, and checked the Lithuanian.
- I still have to run the setup steps with my own accounts, and test the app on real phones.

## Results

Done so far: design document, clickable prototype, and the real version of the site with its Supabase schema. Not yet done: deployment and testing with family members' phones.

## Reflection

*(To fill in after the family test.)*
