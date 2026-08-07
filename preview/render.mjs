/**
 * Renders every scenario in scenarios.js to ./renders as a PNG, plus a contact
 * sheet. Used to eyeball the design without the Connect IQ simulator.
 *
 *   node render.mjs            # all scenarios at 454
 *   node render.mjs 390        # all scenarios at 390
 */
import { createServer } from 'node:http';
import { readFileSync, mkdirSync, existsSync } from 'node:fs';
import { dirname, join, extname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { chromium } from 'playwright';

const here = dirname(fileURLToPath(import.meta.url));
const out = join(here, 'renders');
const size = Number(process.argv[2]) || 454;

if (!existsSync(join(here, 'fonts'))) {
  console.error('Missing ./fonts — run `node setup-fonts.mjs` first.');
  process.exit(1);
}
mkdirSync(out, { recursive: true });

const MIME = {
  '.html': 'text/html',
  '.js': 'text/javascript',
  '.woff2': 'font/woff2',
  '.png': 'image/png',
};

const server = createServer((req, res) => {
  const path = join(here, decodeURIComponent(req.url.split('?')[0]).replace(/^\/+/, '') || 'index.html');
  try {
    const body = readFileSync(path);
    res.writeHead(200, { 'content-type': MIME[extname(path)] || 'application/octet-stream' });
    res.end(body);
  } catch {
    res.writeHead(404).end('not found');
  }
});

await new Promise((r) => server.listen(0, '127.0.0.1', r));
const port = server.address().port;

const browser = await chromium.launch();
const page = await browser.newPage({ deviceScaleFactor: 2, viewport: { width: 900, height: 700 } });
page.on('console', (m) => m.type() === 'error' && console.error('page error:', m.text()));
await page.goto(`http://127.0.0.1:${port}/index.html`);
await page.evaluate(() => document.fonts.ready.then(() => true));

const names = await page.evaluate(() => Object.keys(window.ReconScenarios.SCENARIOS));

for (const name of names) {
  await page.evaluate(
    ({ name, size }) => {
      const s = window.ReconScenarios.SCENARIOS[name];
      const c = document.getElementById('face');
      const ratio = 2;
      c.width = size * ratio;
      c.height = size * ratio;
      c.style.width = size + 'px';
      c.style.height = size + 'px';
      const ctx = c.getContext('2d');
      ctx.setTransform(ratio, 0, 0, ratio, 0, 0);
      window.ReconFace.draw(ctx, size, s.data, { ...(s.opts || {}), weekdayLocale: 'ko' });
      document.getElementById('cap').textContent = s.label;
    },
    { name, size },
  );
  const file = join(out, `${name}-${size}.png`);
  await page.locator('#face').screenshot({ path: file });
  console.info('wrote', file);
}

/* contact sheet: every scenario side by side on one canvas */
const sheet = await page.evaluate(
  ({ names, size }) => {
    const cols = 3;
    const rows = Math.ceil(names.length / cols);
    const pad = 22;
    const cv = document.createElement('canvas');
    const ratio = 2;
    cv.width = (cols * size + (cols + 1) * pad) * ratio;
    cv.height = (rows * size + (rows + 1) * pad) * ratio;
    const ctx = cv.getContext('2d');
    ctx.setTransform(ratio, 0, 0, ratio, 0, 0);
    ctx.fillStyle = '#14171a';
    ctx.fillRect(0, 0, cv.width, cv.height);
    names.forEach((name, i) => {
      const s = window.ReconScenarios.SCENARIOS[name];
      const x = pad + (i % cols) * (size + pad);
      const y = pad + Math.floor(i / cols) * (size + pad);
      ctx.save();
      ctx.translate(x, y);
      window.ReconFace.draw(ctx, size, s.data, { ...(s.opts || {}), weekdayLocale: 'ko' });
      ctx.restore();
    });
    return cv.toDataURL('image/png');
  },
  { names, size },
);

const { writeFileSync } = await import('node:fs');
writeFileSync(join(out, `contact-sheet-${size}.png`), Buffer.from(sheet.split(',')[1], 'base64'));
console.info('wrote', join(out, `contact-sheet-${size}.png`));

await browser.close();
server.close();
