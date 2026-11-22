# SILONG · Shelter on the Go

A front-end prototype of SILONG, a smart umbrella rental service in Bonifacio Global City (BGC), Taguig. This is a reworked copy of the [original prototype](https://moisesojano-spec.github.io/silong/), which stays unchanged.

## What changed

- **Pay as you go.** There is no plan to pick. You scan the QR code on a Silongan, take an umbrella, and return it to any Silongan. Your linked GCash, Maya or card is charged once, on return: ₱15 for the first hour, ₱20 up to 3 hours, ₱25 up to 6 hours and ₱40 for a day. One rental never costs more than ₱225, the price of the umbrella, and at that point the umbrella is yours.
- **Ask Kuya Silong.** The mascot is now a helper. Ask him about prices ("how much for 2 hours?"), renting, returns, lost umbrellas, payment, the Silongan locations or today's weather, in English or Tagalog, and he answers from SILONG's help content and your live rental. It all runs in the browser: no AI service, no account, nothing sent anywhere.
- **Much faster, same picture quality.** The images are the original files, at full quality, but each is stored once instead of being pasted into the page up to five times. The first screen no longer waits for the whole page or the web fonts to arrive.
- **Try it without signing up.** "Try the demo" creates a throwaway account on your device in one tap.
- **Phones, tablets and PCs.** Tested on screens from a 360-pixel-wide phone through iPad mini, iPad Air and iPad Pro in both orientations to full-HD monitors. Tablets get two-column layouts, short screens (1366×768 laptops, iPads held sideways) get a compact sidebar, text fields are large enough that iPhones and iPads don't zoom in when you tap them, and the site can be added to the home screen like an app. On wide monitors the home page becomes a dashboard.
- **Rain or shine.** The weather card shows today's UV peak and suggests an umbrella as shade on strong-sun days.
- **Smaller fixes.** Kuya Silong is there from the first screen on every device, with his own spot in the sidebar on wide screens, machines are named the same way everywhere, developer notes are gone from the screens, the FAQ and terms match the new model, and the site has a favicon and link-preview tags.

## About this prototype

Everything is simulated. Accounts, rentals and payments live in your browser's local storage: no money moves and no umbrella is released.

It is a single static page (`index.html`, the `img` folder and `manifest.webmanifest`). Open it in a browser, or publish the folder with GitHub Pages as is.
