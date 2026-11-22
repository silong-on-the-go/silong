# SILONG · Shelter on the Go

A front-end prototype of SILONG, a smart umbrella rental service in Bonifacio Global City (BGC), Taguig. This is a reworked copy of the [original prototype](https://moisesojano-spec.github.io/silong/), which stays unchanged.

Live demo: https://silong-on-the-go.github.io/silong/
The real app, before launch: https://silong-on-the-go.github.io/app/ (repo [silong-on-the-go/app](https://github.com/silong-on-the-go/app))

## What changed

- **Pay as you go.** There is no plan to pick. You scan the QR code on a Silongan, take an umbrella, and return it to any Silongan. Your linked GCash, Maya or card is charged once, on return: ₱15 for the first hour, ₱20 up to 3 hours, ₱25 up to 6 hours and ₱40 for a day. One rental never costs more than ₱225, the price of the umbrella, and at that point the umbrella is yours.
- **Ask Kuya Silong.** The mascot is now a helper. Ask him about prices ("how much for 2 hours?"), renting, returns, lost umbrellas, payment, the Silongan locations or today's weather, in English or Filipino, and he answers from SILONG's help content and your live rental. It all runs in the browser. There is no AI service, and your questions never leave your device.
- **A real map of BGC.** The map is OpenStreetMap, free and with no key needed. You can pan and zoom it, and "Find the one nearest me" uses your location to show the closest Silongan and the walking time. The pins are placeholders until the machines are installed; their positions are set in `KIOSKS` in `index.html`.
- **Scan with your camera.** "Scan with camera" in the unlock dialog reads a Silongan's QR code. A phone's own camera app works too: each printed code is a link that opens SILONG with that machine already chosen. `qr.html` prints one code per machine.
- **Works offline, and opens instantly on repeat visits.** A service worker (`sw.js`) keeps a copy of the app on the device. Without a signal, the app still opens, with the last saved weather and a simple map.
- **Rain and heat alerts.** Turn them on from the home screen or from Account, and SILONG sends a phone notification before rain (a 50% chance or more in the next few hours) or strong sun (UV 8 or more) in BGC. The forecast comes from Open-Meteo.
- **English or Filipino.** One tap switches every screen, and Kuya Silong's answers, between English and Filipino. The Filipino text is in `lang-fil.js`.
- **A real app alongside the demo.** [The real app](https://silong-on-the-go.github.io/app/) runs this same code with real accounts (Supabase), launch news, a support inbox and a visit counter, while renting says "launching soon" until the machines are in. This demo keeps everything simulated and on the device.
- **A privacy-friendly visit counter** in the real app. [stats.html](https://silong-on-the-go.github.io/app/stats.html) shows visits, sign-ups, questions to Kuya Silong and QR scans, by day and by kind of device. There are no cookies, and the counter saves nothing that identifies a person: only what happened, the kind of device and the language. It respects Do Not Track.
- **Much faster, same picture quality.** The images are the original files, at full quality, but each is stored once instead of being pasted into the page up to five times. The first screen no longer waits for the whole page or the web fonts to arrive.
- **Try it without signing up.** "Try the demo" starts a throwaway guest account in one tap.
- **Phones, tablets and PCs.** Tested on screens from a 360-pixel-wide phone through iPad mini, iPad Air and iPad Pro in both orientations to full-HD monitors. Tablets get two-column layouts, short screens (1366×768 laptops, iPads held sideways) get a compact sidebar, text fields are large enough that iPhones and iPads don't zoom in when you tap them, and the site can be added to the home screen like an app. On wide monitors the home page becomes a dashboard.
- **Rain or shine.** The weather card shows today's UV peak and suggests an umbrella as shade on strong-sun days.
- **Smaller fixes.** Kuya Silong is there from the first screen on every device, with his own spot in the sidebar on wide screens. Machines are named the same way everywhere, developer notes are gone from the screens, the FAQ and terms match the new model, and the site has a favicon and link-preview tags.

## The real app

This repo is also the source of [the real app](https://silong-on-the-go.github.io/app/). Both sites run the same `index.html`; what differs is `config.js`:

- **Here (the demo)** `config.js` is empty, so everything is simulated and accounts live in the browser.
- **In [silong-on-the-go/app](https://github.com/silong-on-the-go/app)** `config.js` sets `MODE: 'live'` and connects the Supabase project. That gives real accounts, launch news, support messages and the visit counter, while renting and payments say "launching soon".

The two sites share one address but never share stored data or offline copies.

To publish a change to both: commit and push here, then run `node tools/build-app.mjs ../silong-app` and commit and push the app repo. The app's README covers its database, the launch list and what's left before launch.

## Good to know

- **Alerts** reach the phone while SILONG is open. On Android, once SILONG is added to the home screen, they also arrive in the background, at most every few hours and as often as the phone allows. On iPhone, SILONG has to be added to the home screen before it can show notifications at all. Alerts that arrive on time even when the app is closed need a small server sending web push.
- **Payments, unlocking and returns are simulated.** No money moves and no umbrella is released. The camera scan and the printed QR links choose a machine and start a demo rental.
- **The map pictures come from OpenStreetMap's own servers.** They are free for light use such as this prototype. Before a public launch, move to a map service with a plan (for example MapTiler or Stadia Maps), or put a Google Maps key in `config.js`, because OpenStreetMap's [tile policy](https://operations.osmfoundation.org/policies/tiles/) doesn't allow heavy use.

## Files

It is a static site: publish the folder with GitHub Pages as is.

| File | What it is |
| --- | --- |
| `index.html` | The whole app |
| `config.js` | Public settings. Empty in the demo; the real app's copy sets `MODE: 'live'` and its Supabase project |
| `lang-fil.js` | The Filipino text |
| `sw.js` | The offline copy and the alerts. Change `VERSION` whenever the site changes, so phones pick up the new files |
| `qr.html` | Printable QR codes, one per Silongan |
| `stats.html` | The visit counter |
| `supabase/setup.sql` | The database setup for the real app's accounts, support messages, launch list and counter |
| `tools/build-app.mjs` | Copies this code into the real app's repo |
| `manifest.webmanifest`, `img/` | The app icon, the images and the home-screen settings |
