# Luka's Letter to Santa: project design

Status: draft for review. Nothing has been built yet.

## 1. Goals

- Show a funny, authentic letter from Luka (18 months) to Santa.
- Show a wish list with pictures and example links.
- Let family reserve a gift, with reservations visible to everyone in real time.
- Be easy to use on a phone, with no sign-up.

Out of scope for the first version: payments, buying inside the app, user accounts, multiple children.

## 2. Users

| User | What they do |
|---|---|
| Family member (grandparent, aunt, uncle) | Opens the link, reads the letter, reserves a gift |
| Parents (Milda, Justas) | Write the letter, manage the gift list, fix mistakes |

## 3. Decisions so far

| Question | Decision |
|---|---|
| Who sees who reserved what? | Parents do not need to see it in the final app. A **test mode** shows reserver names so we can check the feature before launch, then it is switched off. |
| Language | Lithuanian only |
| Reservation name | Family member **picks their name from a list** (used for the test mode view only) |
| Un-reserve | Only the person who made the reservation, identified by a **secret code saved on their device**, not by their name |
| Family list | Inga, Alvyra, Emilija, Aidas, Alvydas |
| Look and feel | Handwritten by Luka, on a cream letter with a red and green candy-stripe border (the left-hand letter in the reference image `Letter-To-Santa-Templates-Featured-Image-728x410.jpg.webp`) |

## 4. Screens

```
Home (letter)  →  Wish list
                      ↑
                 Admin page (parents only)
```

All text is in Lithuanian.

1. **Letter page.** The opening screen, styled like the reference letter:
   - cream paper with a candy-stripe border in red and green
   - "Brangus Kalėdų Seneli," in a handwriting font, written as if by Luka
   - dotted writing lines, a little Santa and a nutcracker drawing in the corners, and a "Myliu," sign-off with a scribble signature
   - a button at the bottom: "Žiūrėti Lukos norų sąrašą" (See Luka's wish list)
2. **Wish list page.** The same paper look. Cards in one column on a phone. Each card has:
   - a picture
   - a gift name and a one-line note, for example "2 metų dydis, bet kokia spalva"
   - an example shop link
   - a status: **Laisva** (available) or **Rezervuota** (reserved)
   - a **Rezervuoti** button, or **Atsisakyti rezervacijos** if the gift is reserved by you
3. **Name picker.** The first time, the family member picks their name from the list. The choice is not remembered: the picker is empty each time the app is opened.
4. **Admin page.** Behind a parents' passcode. Add, edit and remove gifts, edit the family list, and switch test mode on or off.

### Who sees what

| Viewer | Sees on a reserved gift |
|---|---|
| Family member, own reservation (same device) | "Rezervavai tu" and an un-reserve button |
| Family member, someone else's reservation | "Rezervuota" only, no name and no button |
| Parents, test mode **on** | "Rezervuota (Vardas)" so we can check it works |
| Parents, test mode **off** (launch) | "Rezervuota" only |

Hiding the name keeps some surprise for you, and it also stops family from comparing who got what.

## 5. Letter content

Written in Lithuanian, in Luka's voice, in short, playful sentences. Planned parts, following the reference letter:

- Greeting: "Brangus Kalėdų Seneli,"
- "Mano vardas Luka, man 1,5 metų." (My name is Luka, I am 1.5 years old.)
- Good-girl report, with a few honest "only sometimes naughty" confessions:
  - she throws food on the floor ("primetė maisto ant žemės")
  - she shreds the toilet paper ("išpešiojo tualetinį popierių")
  - she keeps taking her shoes off ("nuolat nusiimineja batus")
- A teaser for the wish list
- A sign-off, "Myliu, Luka", with a scribble signature

### Handwriting font

The font must support Lithuanian letters (ą, č, ę, ė, į, š, ų, ū, ž). Candidates from Google Fonts with the Latin Extended set: **Caveat**, **Patrick Hand** and **Kalam**. We will test them with real Lithuanian text before choosing. A baby's handwriting is wobbly, so a slightly uneven font with small random tilts on each line will feel more like Luka.

## 6. Data model

**Gift**

| Field | Type | Notes |
|---|---|---|
| id | text | unique |
| title | text | for example "Wooden stacking rings" |
| note | text | size, colour, why she would love it |
| image_url | text | picture of the gift |
| link_url | text | example shop link |
| sort_order | number | display order |

**Reservation** (at most one per gift)

| Field | Type | Notes |
|---|---|---|
| gift_id | text | unique, which prevents double booking |
| family_member_id | text | who reserved it, from the family list (shown only in test mode) |
| owner_code | text | secret random code made by the device, never shown on screen |
| reserved_at | timestamp | |

**Family member** (the list people pick from)

| Field | Type | Notes |
|---|---|---|
| id | text | unique |
| display_name | text | for example "Močiutė Ona" |

**Settings**

| Field | Type | Notes |
|---|---|---|
| test_mode | true/false | when true, parents see who reserved each gift |

## 7. How reservations work

```
Family member picks their name (once), then taps Rezervuoti
        ↓
App asks the database to save a reservation for that gift
        ↓
Database accepts it only if the gift is still free
        ↓
All open screens update and show "Rezervuota"
```

The "only if still free" check happens in the database, not just in the app. If two people tap at the same moment, one succeeds and the other sees "Atsiprašome, ši dovana ką tik buvo rezervuota."

**Un-reserve:** the first time someone reserves a gift, their phone or computer makes a random secret code and saves it in the browser. The code is stored with the reservation. The database deletes a reservation only if the code sent matches the saved one. Nobody types anything, and picking someone else's name does not help.

**Limitations:**
- If someone reserves on one device and later opens the app on another (or clears their browser data), the app will not recognise them. They ask you to cancel it from the admin page. This should be rare.
- The code is a convenience lock for family, not strong security. That is enough for this app.

**Alternative considered:** a personal link per person (for example `.../?p=k3x9`). It works on any device, but you must send five different links. The device code keeps it to one shared link.

## 8. Technology

A static web page (HTML, CSS, JavaScript) plus a small hosted database for the shared reservations.

| Part | Proposed choice | Why |
|---|---|---|
| Front end | Plain HTML, CSS and JavaScript | Simple, no build step, easy to review |
| Shared data | Supabase or Firebase (free tier) | Real-time updates and a uniqueness check, no server of our own |
| Hosting | GitHub Pages, Netlify or similar | Free, one shareable link |
| Images | Stored in the project folder | Works offline and does not depend on shop sites |

Alternative: build it as a Claude Artifact with its shared database. That is the quickest route, but family would need access through Claude, so a normal web link is the better fit.

## 9. Privacy and safety

- The database keys go in a `.env` file (git-ignored) and are described in the README. No keys in the code.
- Only the display names from the family list are stored. No emails, addresses or phone numbers.
- The link is not announced publicly. A simple family passcode on the first visit keeps strangers out.
- Photos of Luka: share only ones the parents are happy to have behind that link.
- Gift links are examples only. The app does not track purchases.

## 10. Build plan

1. Write the Lithuanian letter text, make the family list, and collect 8 to 12 gift ideas with pictures and links.
2. Build the letter page in the candy-stripe paper style, and test the handwriting fonts with Lithuanian text.
3. Build the wish list with fixed sample data.
4. Connect the database and make reservations shared and real time.
5. Add the name picker, the un-reserve rule, the family passcode and the admin page with test mode.
6. Test with test mode **on**: two people reserve the same gift at once, un-reserve someone else's gift, and check it all on phones.
7. Switch test mode **off**, publish and send the link to family.

## 11. Still to decide

1. **Gift pictures:** one image per gift (Milda will provide them), plus an example shop link for each.
2. **Gift notes:** a short note per gift, for example size or colour.
3. **Spelling:** check the Lithuanian in the letter confessions above.
4. **Extras:** a thank-you page after Christmas, or a countdown to Christmas?

### Gift list (first draft)

| # | Gift (Lithuanian) | Note |
|---|---|---|
| 1 | Interaktyvus žaisliukas voniai | Bath toy |
| 2 | Piešimo lentelė | Drawing board |
| 3 | Žodžių kortelės su paveiksleliais | Picture word cards |
| 4 | Pasispiriama mašinytė | Ride-on (push-along) car |
| 5 | Lėlės vežimėlis | Doll's pram |
| 6 | Traktoriukas | Toy tractor |
