/**
 * Copies the Noto Sans KR subsets the preview needs out of node_modules into
 * ./fonts. Run once after `npm install`. The fonts directory is gitignored —
 * only the rendered PNGs in ./out are committed.
 */
import { copyFileSync, mkdirSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const src = join(here, 'node_modules', '@fontsource', 'noto-sans-kr', 'files');
const dst = join(here, 'fonts');

if (!existsSync(src)) {
  console.error('Missing @fontsource/noto-sans-kr. Run `npm install` in this directory first.');
  process.exit(1);
}

mkdirSync(dst, { recursive: true });

for (const weight of [400, 500, 600, 700]) {
  for (const [subset, prefix] of [
    ['latin', 'latin'],
    ['korean', 'kr'],
  ]) {
    copyFileSync(
      join(src, `noto-sans-kr-${subset}-${weight}-normal.woff2`),
      join(dst, `${prefix}-${weight}.woff2`),
    );
  }
}

console.info(`fonts ready -> ${dst}`);
