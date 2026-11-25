// Builds the live-update bundle:
//   release/bundle.zip    - the www/ contents, zipped (stored, no deps)
//   release/bundle.bin    - the SAME bytes, for Hostinger-style hosting
//                           (many shared hosts refuse to serve .zip)
//   release/latest.json   - { version, url, checksum } manifest
// The assets keep STABLE names so the app's update URLs never change
// between versions. The manifest's bundle URL defaults to GitHub
// Releases; set BUNDLE_URL to publish the manifest for another host
// (e.g. BUNDLE_URL=https://example.com/app-updates/bundle.bin).
// Run: npm run bundle
import { createHash } from 'node:crypto';
import { readdirSync, readFileSync, writeFileSync, mkdirSync, statSync } from 'node:fs';
import { join, relative } from 'node:path';

const ROOT = new URL('..', import.meta.url).pathname;
const WWW = join(ROOT, 'www');
const OUT = join(ROOT, 'release');
const OWNER_REPO = 'kaua-silbershlach-parodes/platform-blank-template';

// The bundle version lives in www/version.json: it ships inside the
// bundle and is what the app compares the manifest against.
const version = JSON.parse(readFileSync(join(WWW, 'version.json'), 'utf8')).version;

// --- minimal ZIP writer (store method) with CRC32 -------------------
const CRC_TABLE = (() => {
  const table = new Int32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    table[n] = c;
  }
  return table;
})();

function crc32(buf) {
  let c = 0xffffffff;
  for (let i = 0; i < buf.length; i++) c = CRC_TABLE[(c ^ buf[i]) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}

function collect(dir, base, out) {
  for (const name of readdirSync(dir).sort()) {
    const full = join(dir, name);
    if (statSync(full).isDirectory()) collect(full, base, out);
    else out.push({ name: relative(base, full).split('\\').join('/'), data: readFileSync(full) });
  }
  return out;
}

function zipStore(files) {
  const chunks = [];
  const central = [];
  let offset = 0;
  for (const f of files) {
    const nameBuf = Buffer.from(f.name, 'utf8');
    const crc = crc32(f.data);
    const local = Buffer.alloc(30);
    local.writeUInt32LE(0x04034b50, 0);
    local.writeUInt16LE(20, 4);
    local.writeUInt16LE(0x0800, 6); // UTF-8 flag
    local.writeUInt16LE(0, 8); // store
    local.writeUInt32LE(crc, 14);
    local.writeUInt32LE(f.data.length, 18);
    local.writeUInt32LE(f.data.length, 22);
    local.writeUInt16LE(nameBuf.length, 26);
    chunks.push(local, nameBuf, f.data);
    const cen = Buffer.alloc(46);
    cen.writeUInt32LE(0x02014b50, 0);
    cen.writeUInt16LE(20, 4);
    cen.writeUInt16LE(20, 6);
    cen.writeUInt16LE(0x0800, 8);
    cen.writeUInt16LE(0, 10);
    cen.writeUInt32LE(crc, 16);
    cen.writeUInt32LE(f.data.length, 20);
    cen.writeUInt32LE(f.data.length, 24);
    cen.writeUInt16LE(nameBuf.length, 28);
    cen.writeUInt32LE(offset, 42);
    central.push(cen, nameBuf);
    offset += 30 + nameBuf.length + f.data.length;
  }
  const centralSize = central.reduce((s, b) => s + b.length, 0);
  const end = Buffer.alloc(22);
  end.writeUInt32LE(0x06054b50, 0);
  end.writeUInt16LE(files.length, 8);
  end.writeUInt16LE(files.length, 10);
  end.writeUInt32LE(centralSize, 12);
  end.writeUInt32LE(offset, 16);
  return Buffer.concat([...chunks, ...central, end]);
}
// ---------------------------------------------------------------------

const files = collect(WWW, WWW, []);
const zip = zipStore(files);
mkdirSync(OUT, { recursive: true });
writeFileSync(join(OUT, 'bundle.zip'), zip);
writeFileSync(join(OUT, 'bundle.bin'), zip);
const checksum = createHash('sha256').update(zip).digest('hex');
const manifest = {
  version,
  url: process.env.BUNDLE_URL ||
    `https://github.com/${OWNER_REPO}/releases/download/capacitor-v${version}/bundle.zip`,
  checksum,
};
writeFileSync(join(OUT, 'latest.json'), JSON.stringify(manifest, null, 2) + '\n');
console.log(`bundle.zip: ${zip.length} bytes, ${files.length} files, version ${version}`);
console.log(`latest.json: sha256 ${checksum}`);
