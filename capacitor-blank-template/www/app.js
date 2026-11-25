'use strict';

// Capacitor Blank Template - web shell logic + GitHub live updates.
//
// Update design (no server, no cloud account):
// - GitHub Releases of this repository host two stable-named assets:
//   latest.json (version manifest) and bundle.zip (the web bundle).
// - "releases/latest/download/<asset>" always resolves to the newest
//   published release, so the URLs below never change.
// - The app fetches the manifest, compares versions, and drives the
//   Capgo updater plugin (manual mode) to download and apply the new
//   bundle natively. The native shell (APK) itself is versioned
//   separately and rarely changes.

// Update channel. Default: GitHub Releases (below). Hostinger (or any
// static hosting) also works: upload latest.json + bundle.bin to a
// public folder and point this constant at that latest.json instead,
// e.g. 'https://aeliteestrangeira.com/capacitor-updates/latest.json'
// (tested live — see README "Hostinger support"). The bundle is named
// bundle.bin there because shared-hosting rules commonly refuse to
// serve .zip files; the updater unzips by content, not by extension.
const LATEST_JSON_URL =
  'https://raw.githubusercontent.com/kaua-silbershlach-parodes/platform-blank-template/main/capacitor-blank-template/latest.json';

const versionEl = document.getElementById('bundle-version');
const whatsNewEl = document.getElementById('whats-new');
const stateEl = document.getElementById('update-state');
const messageEl = document.getElementById('update-message');
const logEl = document.getElementById('update-log');
const progressWrap = document.getElementById('progress-wrap');
const progressBar = document.getElementById('progress-bar');
const btnCheck = document.getElementById('btn-check');

let currentVersion = '0.0.0';
let updater = null;

function log(line) {
  const li = document.createElement('li');
  const time = new Date().toLocaleTimeString();
  li.textContent = `[${time}] ${line}`;
  logEl.prepend(li);
}

function setState(state, text) {
  stateEl.textContent = state.replace(/-/g, ' ');
  stateEl.className = `state state-${state}`;
  if (text) messageEl.textContent = text;
}

function isNewer(remote, local) {
  const r = remote.split('.').map(Number);
  const l = local.split('.').map(Number);
  for (let i = 0; i < Math.max(r.length, l.length); i++) {
    const rv = r[i] || 0;
    const lv = l[i] || 0;
    if (rv !== lv) return rv > lv;
  }
  return false;
}

async function checkForUpdates(manual) {
  if (!updater) {
    setState('idle', 'Live updates run inside the installed app (native shell).');
    if (manual) log('Web preview: the updater plugin is not available here.');
    return;
  }
  try {
    setState('checking', 'Checking GitHub Releases for a newer bundle…');
    log('Checking for updates…');
    const res = await fetch(LATEST_JSON_URL, { cache: 'no-store' });
    if (!res.ok) throw new Error(`manifest HTTP ${res.status}`);
    const latest = await res.json();
    log(`Latest bundle on GitHub: ${latest.version} (current: ${currentVersion}).`);
    if (!isNewer(latest.version, currentVersion)) {
      setState('idle', `You are on the latest bundle (${currentVersion}).`);
      log('No update needed.');
      return;
    }
    setState('downloading', `Bundle ${latest.version} found. Downloading…`);
    progressWrap.hidden = false;
    progressBar.style.width = '0%';
    const bundle = await updater.download({
      url: latest.url,
      version: latest.version,
      checksum: latest.checksum || undefined,
    });
    progressBar.style.width = '100%';
    setState('downloaded', `Bundle ${latest.version} downloaded. Applying…`);
    log(`Bundle ${latest.version} downloaded (id ${bundle.id}). Applying now.`);
    // set() swaps the served bundle and reloads the app into it.
    await updater.set({ id: bundle.id });
  } catch (err) {
    setState('error', `Update check failed: ${err.message || err}`);
    log(`Update error: ${err.message || err}`);
  }
}

async function init() {
  try {
    const v = await (await fetch('version.json', { cache: 'no-store' })).json();
    currentVersion = v.version;
    versionEl.textContent = v.version;
    if (v.notes) {
      whatsNewEl.textContent = v.notes;
      whatsNewEl.hidden = false;
    }
    log(`App started, bundle version ${v.version}.`);
  } catch {
    versionEl.textContent = '?';
    log('Could not read version.json.');
  }

  const cap = window.Capacitor;
  if (cap && cap.Plugins && cap.Plugins.CapacitorUpdater) {
    updater = cap.Plugins.CapacitorUpdater;
    // Required: confirms this bundle works, so the plugin does not
    // roll back to the previous one on the next launch.
    try { await updater.notifyAppReady(); } catch { /* older bundle safety */ }
    updater.addListener('download', (info) => {
      if (typeof info.percent === 'number') {
        progressBar.style.width = `${info.percent}%`;
        setState('downloading', `Downloading update… ${info.percent}%`);
      }
    });
    updater.addListener('downloadFailed', (info) => {
      setState('error', 'Download failed.');
      log(`Download failed: ${JSON.stringify(info)}`);
    });
    // Automatic check shortly after launch.
    setTimeout(() => checkForUpdates(false), 2500);
  } else {
    log('Native updater not detected (web preview mode).');
  }

  btnCheck.addEventListener('click', () => checkForUpdates(true));
}

document.addEventListener('DOMContentLoaded', init);
