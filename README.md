# SILONG · Shelter on the Go

A front-end prototype of SILONG, a smart umbrella rental service in Bonifacio Global City (BGC), Taguig. This is a reworked copy of the [original prototype](https://moisesojano-spec.github.io/silong/), which stays unchanged.

Live: https://silong-on-the-go.github.io/silong/

## What changed

- **Pay as you go.** There is no plan to pick. You scan the QR code on a Silongan, take an umbrella, and return it to any Silongan. Your linked GCash, Maya or card is charged once, on return: ₱15 for the first hour, ₱20 up to 3 hours, ₱25 up to 6 hours and ₱40 for a day. One rental never costs more than ₱225, the price of the umbrella, and at that point the umbrella is yours.
- **Ask Kuya Silong.** The mascot is now a helper. Ask him about prices ("how much for 2 hours?"), renting, returns, lost umbrellas, payment, the Silongan locations or today's weather, in English or Filipino, and he answers from SILONG's help content and your live rental. It all runs in the browser. There is no AI service, and your questions never leave your device.
- **A real map of BGC.** The map is OpenStreetMap, free and with no key needed. You can pan and zoom it, and "Find the one nearest me" uses your location to show the closest Silongan and the walking time. The pins are placeholders until the machines are installed; their positions are set in `KIOSKS` in `index.html`.
- **Scan with your camera.** "Scan with camera" in the unlock dialog reads a Silongan's QR code. A phone's own camera app works too: each printed code is a link that opens SILONG with that machine already chosen. `qr.html` prints one code per machine.
- **Works offline, and opens instantly on repeat visits.** A service worker (`sw.js`) keeps a copy of the app on the device. Without a signal, the app still opens, with the last saved weather and a simple map.
- **Rain and heat alerts.** Turn them on from the home screen or from Account, and SILONG sends a phone notification before rain (a 50% chance or more in the next few hours) or strong sun (UV 8 or more) in BGC. The forecast comes from Open-Meteo.
- **English or Filipino.** One tap switches every screen, and Kuya Silong's answers, between English and Filipino. The Filipino text is in `lang-fil.js`.
- **Real accounts, once switched on.** With a free Supabase project, sign-ups, logins, rentals and SILONG credit carry over between phone, tablet and PC, and support messages reach the team. The steps are below. Until then, accounts stay in the browser, as before.
- **A privacy-friendly visit counter.** `stats.html` shows visits, demo starts, sign-ups, rentals, questions to Kuya Silong and QR scans, by day and by kind of device. There are no cookies, and the counter saves nothing that identifies a person: only what happened, the kind of device and the language. It respects Do Not Track, and it switches on together with Supabase.
- **Much faster, same picture quality.** The images are the original files, at full quality, but each is stored once instead of being pasted into the page up to five times. The first screen no longer waits for the whole page or the web fonts to arrive.
- **Try it without signing up.** "Try the demo" starts a throwaway guest account in one tap.
- **Phones, tablets and PCs.** Tested on screens from a 360-pixel-wide phone through iPad mini, iPad Air and iPad Pro in both orientations to full-HD monitors. Tablets get two-column layouts, short screens (1366×768 laptops, iPads held sideways) get a compact sidebar, text fields are large enough that iPhones and iPads don't zoom in when you tap them, and the site can be added to the home screen like an app. On wide monitors the home page becomes a dashboard.
- **Rain or shine.** The weather card shows today's UV peak and suggests an umbrella as shade on strong-sun days.
- **Smaller fixes.** Kuya Silong is there from the first screen on every device, with his own spot in the sidebar on wide screens. Machines are named the same way everywhere, developer notes are gone from the screens, the FAQ and terms match the new model, and the site has a favicon and link-preview tags.

## Switch on real accounts and the visit counter

This takes about ten minutes on Supabase's free plan.

1. Sign in at [supabase.com](https://supabase.com) and create a new project called `silong`. Choose the Singapore region, the closest to Manila. Supabase asks for a database password: keep it to yourself, because the site never needs it.
2. Open **SQL Editor**, click **New query**, paste all of [`supabase/setup.sql`](supabase/setup.sql) and click **Run**. This creates the tables and their access rules, and it is safe to run again.
3. Open **Authentication → Sign In / Providers** and turn on **Allow anonymous sign-ins**, which powers "Try the demo". For the prototype, also turn off **Confirm email**, because Supabase's built-in email sender only allows a few emails an hour. Before a real launch, connect a proper email sender and turn it back on.
4. Open **Authentication → URL Configuration** and set the **Site URL** to `https://silong-on-the-go.github.io/silong/`.
5. Copy the **Project URL** and the **publishable key** (both are on the project's **Connect** panel) into `config.js`, then publish. Both values are designed to be public: the access rules from step 2 decide what anyone can read or write. Never put a secret or `service_role` key in `config.js`.

The "Prototype status" card on the Account screen then shows "Authentication and accounts: Connected (Supabase)", and `stats.html` starts counting. Support messages arrive in the `tickets` table (**Table Editor → tickets**).

A free project pauses after a week with no activity. Restore it from the Supabase dashboard; the data is kept.

## Good to know

- **Alerts** reach the phone while SILONG is open. On Android, once SILONG is added to the home screen, they also arrive in the background, at most every few hours and as often as the phone allows. On iPhone, SILONG has to be added to the home screen before it can show notifications at all. Alerts that arrive on time even when the app is closed need a small server sending web push.
- **Payments, unlocking and returns are simulated.** No money moves and no umbrella is released. The camera scan and the printed QR links choose a machine and start a demo rental.
- **Google Maps is optional.** Put an API key in `config.js` to use it instead of OpenStreetMap.

## Files

It is a static site: publish the folder with GitHub Pages as is.

| File | What it is |
| --- | --- |
| `index.html` | The whole app |
| `config.js` | Public settings: the Supabase project, and an optional Google Maps key |
| `lang-fil.js` | The Filipino text |
| `sw.js` | The offline copy and the alerts. Change `VERSION` whenever the site changes, so phones pick up the new files |
| `qr.html` | Printable QR codes, one per Silongan |
| `stats.html` | The visit counter |
| `supabase/setup.sql` | The database setup for real accounts and the counter |
| `manifest.webmanifest`, `img/` | The app icon, the images and the home-screen settings |
