// Builds the real SILONG app (silong-on-the-go/app) from this repo's code.
// The demo and the real app run the same index.html. The real app's own config.js sets MODE: 'live',
// which turns on real accounts and turns renting and payments into "launching soon".
//
// usage (from this repo's folder):  node tools/build-app.mjs [path to the app repo, default ../silong-app]
// It copies the shared files and points the link-preview tags at the app's address. It never touches the
// app's config.js or README.md, which belong to the app repo.
import { cpSync, existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const SRC = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const OUT = resolve(process.argv[2] || join(SRC, '..', 'silong-app'));
const DEMO_URL = 'https://silong-on-the-go.github.io/silong/';
const APP_URL = 'https://silong-on-the-go.github.io/app/';
const SHARED = ['lang-fil.js', 'sw.js', 'manifest.webmanifest', 'qr.html', 'stats.html', '.nojekyll', 'img', 'supabase/setup.sql'];

if (!existsSync(join(OUT, 'config.js'))) { console.error(`No config.js in ${OUT}. Create the app's config.js (with MODE: 'live') first.`); process.exit(1); }
if (!/MODE:\s*'live'/.test(readFileSync(join(OUT, 'config.js'), 'utf8'))) { console.error(`${OUT}/config.js doesn't set MODE: 'live'.`); process.exit(1); }

for (const f of SHARED) {
  mkdirSync(dirname(join(OUT, f)), { recursive: true });
  cpSync(join(SRC, f), join(OUT, f), { recursive: true });
}

let html = readFileSync(join(SRC, 'index.html'), 'utf8');
const swaps = [
  [`<meta property="og:url" content="${DEMO_URL}">`, `<meta property="og:url" content="${APP_URL}">`],
  [`<meta property="og:image" content="${DEMO_URL}img/5f47a2806a.png">`, `<meta property="og:image" content="${APP_URL}img/5f47a2806a.png">`],
  ['and manage rentals. Front-end prototype.">', 'and get launch news.">']
];
for (const [a, b] of swaps) {
  if (!html.includes(a)) { console.error('index.html no longer contains: ' + a); process.exit(1); }
  html = html.replace(a, b);
}
writeFileSync(join(OUT, 'index.html'), html);
console.log(`Built the real app in ${OUT}: index.html + ${SHARED.join(', ')}`);
