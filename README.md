# SILONG · Shelter on the Go

A front-end prototype of SILONG, a smart umbrella rental service in Bonifacio Global City (BGC), Taguig. This is a reworked copy of the [original prototype](https://moisesojano-spec.github.io/silong/), which stays unchanged.

## What changed

- **Pay as you go.** There is no plan to pick. You scan the QR code on a Silongan, take an umbrella, and return it to any Silongan. Your linked GCash, Maya or card is charged once, on return: ₱15 for the first hour, ₱20 up to 3 hours, ₱25 up to 6 hours and ₱40 for a day. One rental never costs more than ₱225, the price of the umbrella, and at that point the umbrella is yours.
- **Much faster.** Each image is stored once, as WebP, instead of being pasted into the page up to five times. On the same simulated slow phone connection, the first screen appears in 0.7 s instead of 8.2 s, and the page downloads 112 KB instead of 1,460 KB.
- **Try it without signing up.** "Try the demo" creates a throwaway account on your device in one tap.
- **Built for PC screens too.** The layout uses the full width of the screen, and on wide monitors the home page becomes a dashboard.
- **Rain or shine.** The weather card shows today's UV peak and suggests an umbrella as shade on strong-sun days.
- **Smaller fixes.** Kuya Silong has his own spot in the sidebar and is off by default on phones, machines are named the same way everywhere, developer notes are gone from the screens, the FAQ and terms match the new model, and the site has a favicon and link-preview tags.

## About this prototype

Everything is simulated. Accounts, rentals and payments live in your browser's local storage: no money moves and no umbrella is released.

It is a single static page (`index.html` plus the `img` folder). Open it in a browser, or publish the folder with GitHub Pages as is.
