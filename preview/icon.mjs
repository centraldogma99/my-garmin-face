/**
 * Renders the launcher icon into ../resources/drawables/launcher_icon.png.
 * It is a reduction of the face itself: bezel tick, hero time, trend band.
 *
 *   node icon.mjs [size]      # default 60
 */
import { writeFileSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { chromium } from 'playwright';

const here = dirname(fileURLToPath(import.meta.url));
const size = Number(process.argv[2]) || 60;
const dest = join(here, '..', 'resources', 'drawables');

const browser = await chromium.launch();
const page = await browser.newPage();

const dataUrl = await page.evaluate((S) => {
  const c = document.createElement('canvas');
  c.width = S;
  c.height = S;
  const x = c.getContext('2d');
  const u = (v) => (v * S) / 60;

  x.fillStyle = '#000000';
  x.beginPath();
  x.arc(S / 2, S / 2, S / 2, 0, Math.PI * 2);
  x.fill();

  x.strokeStyle = '#2A323C';
  x.lineWidth = u(2);
  x.beginPath();
  x.arc(S / 2, S / 2, u(27), 0, Math.PI * 2);
  x.stroke();

  // today's marker on the bezel
  x.fillStyle = '#FF6A1A';
  x.fillRect(S / 2 - u(4), u(6), u(8), u(3));

  // the time, reduced to two blocks and the colon
  x.fillStyle = '#F2F5F8';
  x.fillRect(u(13), u(21), u(14), u(13));
  x.fillRect(u(33), u(21), u(14), u(13));
  x.fillStyle = '#FF6A1A';
  x.fillRect(u(28.5), u(23), u(3), u(3));
  x.fillRect(u(28.5), u(29), u(3), u(3));

  // body battery trend
  const h = [4, 5, 7, 8, 7, 6, 5, 4];
  h.forEach((v, i) => {
    x.fillStyle = '#113A4D';
    x.fillRect(u(14 + i * 4), u(48 - v), u(2.6), u(v));
    x.fillStyle = '#35BEF5';
    x.fillRect(u(14 + i * 4), u(48 - v), u(2.6), u(1.6));
  });

  return c.toDataURL('image/png');
}, size);

mkdirSync(dest, { recursive: true });
const file = join(dest, 'launcher_icon.png');
writeFileSync(file, Buffer.from(dataUrl.split(',')[1], 'base64'));
console.info('wrote', file, `${size}x${size}`);

await browser.close();
