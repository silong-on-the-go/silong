/* SILONG service worker: works offline, loads instantly on repeat visits, and shows rain and heat alerts.
   Bump VERSION whenever the site changes so phones pick up the new files.
   The demo registers sw.js and the real app registers sw.js?ns=silongapp, so the two keep separate
   caches even though they share one website address. */
const NS = new URL(location.href).searchParams.get('ns') === 'silongapp' ? 'silongapp' : 'silong';
const VERSION = NS + '-core-2026-11-25g';
const CORE = ['./', 'index.html', 'config.js', 'lang-fil.js', 'manifest.webmanifest', 'qr.html',
  'img/5f47a2806a.png', 'img/5fa28b0e07.png', 'img/581e05ef1a.png', 'img/b3e5dbed33.png', 'img/2724515ba7.png', 'img/d87dedd030.png', 'img/eb52b0bc4b.png',
  'img/icon-180.png', 'img/icon-192.png', 'img/icon-512.png',
  'img/mark-gcash.png', 'img/mark-maya.png', 'img/sample-gcash.png', 'img/sample-maya.png', 'img/sample-bank.png'];
const WEATHER = NS + '-weather', STATE = NS + '-state';

self.addEventListener('install', (e) => {
  e.waitUntil(caches.open(VERSION).then((c) => c.addAll(CORE)).then(() => self.skipWaiting()));
});
self.addEventListener('activate', (e) => {
  e.waitUntil(caches.keys().then((keys) => Promise.all(keys.filter((k) => (k.startsWith(NS + '-core-') && k !== VERSION) || (NS === 'silong' && k === 'silong-tiles')).map((k) => caches.delete(k))))
    .then(() => self.clients.claim()));
});

self.addEventListener('fetch', (e) => {
  const req = e.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (/\.supabase\.(co|in)$/.test(url.hostname)) return;                       /* accounts and data: always live, never cached */
  if (url.origin === location.origin && /stats\.html$/.test(url.pathname)) return; /* stats: always fresh */
  if (req.mode === 'navigate' || (url.origin === location.origin && /(\/|\.html|\.js|\.webmanifest)$/.test(url.pathname))) {
    e.respondWith(networkFirst(e, VERSION, 2000, true)); return;                    /* the app itself: the newest copy if it arrives within 2 s, else the saved one */
  }
  if (url.hostname === 'api.open-meteo.com') { e.respondWith(networkFirst(e, WEATHER, 4000)); return; }
  if (url.hostname === 'tile.openstreetmap.org') return;                     /* map tiles: the browser's own cache, as OpenStreetMap's tile policy asks */
  e.respondWith(cacheFirst(req, VERSION));                                     /* images, fonts, pinned libraries */
});

/* Network first, without long waits: when the network fails, or hasn't answered within `wait` ms, answer with the
   saved copy, and let the fresh copy finish downloading in the background for next time. */
let slowUntil = 0;  /* after a slow or failed page load, the app's other files come straight from the saved copy for a few seconds */
function networkFirst(e, name, wait, app) {
  const req = e.request, cacheP = caches.open(name), page = app && req.mode === 'navigate';
  const key = req.mode === 'navigate' ? req.url.split(/[?#]/)[0] : req;      /* one saved page, whatever the query string */
  let saving = null, quick = false;
  const t0 = Date.now();
  /* the app's own files: always ask the server (a quick "not changed" when nothing is new), never the browser's
     short-term copy, so reopening SILONG while online always gets the newest version */
  const fresh = (app ? fetch(req.mode === 'navigate' ? req.url : req, { cache: 'no-cache', credentials: 'same-origin' }) : fetch(req)).then((res) => {
    if (page && Date.now() - t0 < wait) { quick = true; slowUntil = 0; }     /* the network answered quickly: it's fine again */
    if (res.ok && !res.redirected) { const copy = res.clone(); saving = cacheP.then((c) => c.put(key, copy)); }
    return res;
  });
  e.waitUntil(fresh.then(() => saving).catch(() => {}));                    /* keep the worker alive until the fresh copy is saved */
  return (async () => {
    const first = await Promise.race([fresh.catch(() => null), new Promise((r) => setTimeout(r, app && Date.now() < slowUntil ? 0 : wait, null))]);
    if (first) { if (page) slowUntil = 0; return first; }
    const c = await cacheP;
    const hit = (await c.match(req, { ignoreSearch: true })) || (req.mode === 'navigate' && ((await c.match('index.html')) || (await c.match('./'))));
    if (hit && page && !quick) slowUntil = Date.now() + 15000;
    return hit || fresh;                                                     /* nothing saved yet: wait for the network */
  })();
}
async function cacheFirst(req, name) {
  const cache = await caches.open(name);
  const hit = await cache.match(req);
  if (hit) return hit;
  const res = await fetch(req);
  if (res.ok) cache.put(req, res.clone());  /* CORS responses only: real sizes in storage, and never a saved error page */
  return res;
}

/* ---- Rain and heat alerts ---- */
async function getState() {
  const r = await (await caches.open(STATE)).match('/alerts-state');
  return r ? r.json() : { enabled: false, lang: 'en', lastRain: 0, lastSun: 0 };
}
async function setState(s) { await (await caches.open(STATE)).put('/alerts-state', new Response(JSON.stringify(s), { headers: { 'Content-Type': 'application/json' } })); }

self.addEventListener('message', (e) => {
  const m = e.data || {};
  if (m.type === 'alerts-settings') e.waitUntil(getState().then((s) => setState({ ...s, enabled: !!m.enabled, lang: m.lang || s.lang })));
  if (m.type === 'check-weather') e.waitUntil(checkWeather(m.force, m.lang));
});
self.addEventListener('periodicsync', (e) => { if (e.tag === 'silong-weather') e.waitUntil(checkWeather()); });

async function checkWeather(force, langNow) {
  const st = await getState();
  if (langNow) st.lang = langNow;
  if (!st.enabled && !force) return;
  const fil = st.lang === 'fil', t = (en, tl) => (fil ? tl : en);
  if (force === 'test') {
    return notify(t('Rain and heat alerts are on', 'Naka-on na ang alerts sa ulan at init'),
      t('SILONG will give you a heads-up before rain or strong sun in BGC.', 'Babalaan ka ng SILONG bago umulan o uminit nang husto sa BGC.'), 'silong-alerts-on');
  }
  let j;
  try {
    j = await (await fetch('https://api.open-meteo.com/v1/forecast?latitude=14.5515&longitude=121.0468&hourly=precipitation_probability,uv_index&forecast_hours=4&timezone=Asia%2FManila')).json();
  } catch (err) { return; }
  const h = j && j.hourly; if (!h || !h.time) return;
  let rain = null, sun = null;
  h.time.forEach((time, i) => {
    const p = h.precipitation_probability[i], u = h.uv_index[i];
    if (p >= 50 && (!rain || p > rain.p)) rain = { p, time };
    if (u >= 8 && (!sun || u > sun.u)) sun = { u: Math.round(u), time };
  });
  const at = (time) => new Date(time + ':00+08:00').toLocaleTimeString(fil ? 'fil-PH' : 'en-PH', { hour: 'numeric', timeZone: 'Asia/Manila' });
  const now = Date.now();
  if (rain && (force || now - st.lastRain > 3 * 3600000)) {
    st.lastRain = now; await setState(st);
    return notify(t(`Rain likely around ${at(rain.time)}`, `Malamang umulan bandang ${at(rain.time)}`),
      t(`${rain.p}% chance of rain in BGC. Grab an umbrella at the nearest Silongan.`, `${rain.p}% tsansa ng ulan sa BGC. Kumuha ng payong sa pinakamalapit na Silongan.`), 'silong-rain');
  }
  if (sun && (force || now - st.lastSun > 6 * 3600000)) {
    st.lastSun = now; await setState(st);
    return notify(t(`Strong sun around ${at(sun.time)}`, `Matinding araw bandang ${at(sun.time)}`),
      t(`UV index ${sun.u} in BGC. An umbrella doubles as shade.`, `UV index ${sun.u} sa BGC. Panangga rin sa init ang payong.`), 'silong-sun');
  }
}
function notify(title, body, tag) {
  return self.registration.showNotification(title, { body, tag, icon: 'img/icon-192.png', badge: 'img/icon-192.png', data: { url: './#locations' } });
}
self.addEventListener('notificationclick', (e) => {
  e.notification.close();
  const target = new URL((e.notification.data && e.notification.data.url) || './', self.registration.scope).href;
  e.waitUntil(self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((list) => {
    const open = list.find((c) => c.url.startsWith(self.registration.scope));
    if (open) { open.navigate(target).catch(() => {}); return open.focus(); }
    return self.clients.openWindow(target);
  }));
});
