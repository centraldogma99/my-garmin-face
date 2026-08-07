/**
 * Renders the same face at several font-size multipliers.
 *
 * The device picks its own system fonts and they do NOT scale linearly with
 * the design units, so the layout has to survive them coming out bigger than
 * assumed. This is the check for that.
 *
 *   node font-stress.mjs 416 1.0 1.15 1.3
 */
import { createServer } from 'node:http';
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { dirname, join, extname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { chromium } from 'playwright';

const here = dirname(fileURLToPath(import.meta.url));
const size = Number(process.argv[2]) || 416;
const scales = process.argv.slice(3).map(Number);
const MIME = { '.html': 'text/html', '.js': 'text/javascript', '.woff2': 'font/woff2' };
const server = createServer((req, res) => {
  const path = join(here, (req.url.split('?')[0] || '/').replace(/^\/+/, '') || 'index.html');
  try {
    res.writeHead(200, { 'content-type': MIME[extname(path)] || 'application/octet-stream' });
    res.end(readFileSync(path));
  } catch { res.writeHead(404).end('no'); }
});
await new Promise((r) => server.listen(0, '127.0.0.1', r));
const browser = await chromium.launch();
const page = await browser.newPage({ deviceScaleFactor: 2, viewport: { width: 900, height: 700 } });
await page.goto(`http://127.0.0.1:${server.address().port}/index.html`);
await page.evaluate(() => document.fonts.ready.then(() => true));

const url = await page.evaluate(({ size, scales }) => {
  const pad = 20, n = scales.length;
  const c = document.createElement('canvas'), r = 2;
  c.width = (n * size + (n + 1) * pad) * r;
  c.height = (size + 2 * pad + 26) * r;
  const x = c.getContext('2d');
  x.setTransform(r, 0, 0, r, 0, 0);
  x.fillStyle = '#14171a';
  x.fillRect(0, 0, c.width, c.height);
  scales.forEach((fs, i) => {
    const d = window.ReconScenarios.SCENARIOS.default;
    x.save();
    x.translate(pad + i * (size + pad), pad);
    window.ReconFace.draw(x, size, d.data, { weekdayLocale: 'ko', fontScale: fs });
    x.restore();
    x.fillStyle = '#8b96a0';
    x.font = '600 15px sans-serif';
    x.textAlign = 'center';
    x.fillText(`fontScale ${fs.toFixed(2)}`, pad + i * (size + pad) + size / 2, pad + size + 18);
  });
  return c.toDataURL('image/png');
}, { size, scales });

mkdirSync(join(here, 'renders'), { recursive: true });
const out = join(here, 'renders', `font-stress-${size}.png`);
writeFileSync(out, Buffer.from(url.split(',')[1], 'base64'));
console.info('wrote', out);
await browser.close();
server.close();
