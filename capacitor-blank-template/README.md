# Capacitor Blank Template with Android and iOS Builds, Live Updates, Hostinger Support and Store Publishing

A blank Capacitor template by A Elite Estrangeira: a working mobile
shell (graphical interface, house icon), a reproducible **Android APK
build**, a generated **iOS platform** (built in the cloud by a macOS
workflow), and **live updates** through the Capgo updater plugin in
manual mode — served from **GitHub Releases** or from **your own
Hostinger hosting**, no update server, no cloud account. Hostinger
support covers both legs of the hosting account: the **files** (the
update channel) and the **database** (list databases and open
phpMyAdmin through the API). Store publishing (Google Play + App
Store) is scaffolded in `store/`. Clone it, replace the welcome
panel with your product, and the build, update and publishing
machinery is already done.

## What is inside

| Path | Contents |
|---|---|
| `www/` | The app interface: `index.html`, `styles.css`, `app.js` (shell + update driver), `version.json` (the bundle version), `icon.png` |
| `capacitor.config.ts` | App id `com.aeliteestrangeira.capacitorblanktemplate`, updater plugin in manual mode, native HTTP enabled |
| `android/` | The generated Android platform, with the house launcher icons (all densities, adaptive foreground) and `versionName 1.0.1` |
| `ios/` | The generated iOS platform: Xcode project, bundle ID, 1024×1024 App Icon, updater plugin wired |
| `.github/workflows/` | `ios-build.yml` — builds the iOS app on a macOS runner and packages an unsigned device IPA |
| `scripts/make-bundle.mjs` | Builds the update artifacts: `release/bundle.zip` + `release/bundle.bin` + `release/latest.json` (dependency-free) |
| `scripts/deploy-hostinger.sh` | Publishes the update channel to a Hostinger hosting folder and verifies it byte-for-byte |
| `scripts/hostinger-db.sh` | Lists the Hostinger account's databases and opens phpMyAdmin via the API's one-time sign-on link (never printed) |
| `store/` | Backend scaffolding for Google Play and App Store publishing: credential templates, fastlane lanes (see `store/README.md`) |
| `scripts/*.ps1` | The from-scratch rebuild kit (numbered PowerShell steps, distinct from the `.mjs`/`.sh` utilities above): prerequisites, clone/install, APK build, device install, smoke tests |
| `tests/` | Standalone checks for the two update channels and the build toolchain |
| `package.json` | Dependencies and the `sync`, `apk:debug` and `bundle` scripts |

The interface shows the running bundle version and a live **Updates
panel**: state, download progress, an event log, and a manual check
button. On launch the app checks for updates automatically.

## How live updates work (GitHub is the update server)

- Every release of this repository carries two assets with **stable
  names**: `latest.json` (the version manifest: version, bundle URL,
  SHA-256 checksum) and `bundle.zip` (the `www/` contents).
- `https://raw.githubusercontent.com/kaua-silbershlach-parodes/platform-blank-template/main/capacitor-blank-template/latest.json`
  always resolves to the newest published release — the app fetches
  exactly that URL, so the update address never changes.
- If the manifest version is newer than the running bundle, the app
  downloads `bundle.zip` through the Capgo updater plugin, verifies
  the checksum, applies it natively and reloads into the new
  interface. `notifyAppReady()` confirms each applied bundle;
  a bundle that fails to confirm is rolled back automatically.
- The APK (native shell) is versioned separately and only changes
  when native code changes. Interface changes ship as bundles.
- The update check runs through **native HTTP** (`CapacitorHttp`
  enabled in `capacitor.config.ts`): GitHub's asset host sends no
  CORS headers, so a plain WebView `fetch()` is blocked and the
  check fails with "Failed to fetch". Native HTTP has no CORS.
  (Fixed in 1.0.1 — the 1.0.0 APK could not check for updates.)
- **Proven on a real Android device (2026-11-21):** both channels
  delivered updates over the air, and the app switched channels by
  bundle alone — a Hostinger-born APK received bundle 1.0.3 from
  Hostinger, then 1.0.4 from Hostinger (which pointed it back to
  GitHub), then 1.0.5 from GitHub. The GitHub-born path is equally
  armed: the 1.0.1 APK receives 1.0.2 from GitHub, whose bundle
  points it at Hostinger.

## Hostinger support

The update channel does not need GitHub: any static hosting works,
including a Hostinger shared plan. Point the app at it with the
one-line channel switch documented at the top of `www/app.js`, and
publish with:

```
sh scripts/deploy-hostinger.sh
```

The script builds the bundle with the manifest pointing at your
hosting, uploads `bundle.bin` and then `latest.json` to a public
folder (defaults target `aeliteestrangeira.com/capacitor-updates`
through the Hostinger API helper), and verifies the public channel
byte-for-byte.

Two facts proven live on a Hostinger Single plan
(aeliteestrangeira.com, 2026-11-21):

- The bundle must be named **`bundle.bin`**, not `bundle.zip`: the
  site's own `.htaccess` (a common shared-hosting protection) refuses
  to serve `.zip` (403). Served as `.bin`, the bundle arrives
  **byte-exact** — the sha256 of the public download matches the
  manifest checksum. The updater unzips by content, so the name is
  irrelevant to it.
- A replaced `latest.json` is served **immediately** at its clean
  URL (the hosting marks it no-store) — but the **bundle binary is
  cached by the CDN at its clean URL**: re-uploading a fixed
  `bundle.bin` kept serving the first version while the origin
  already had the new one (proven with a cache-busting query tag).
  The deploy script therefore publishes each bundle under a
  **versioned name** (`bundle-<version>.bin`) that the manifest
  points to — a fresh URL is never stale.

Live test channel: `https://aeliteestrangeira.com/capacitor-updates/latest.json`

The same folder also hosts a **Hostinger-edition APK** (its only
update URL is the Hostinger channel) at
`capacitor-updates/capacitor-blank-template-hostinger.apk` — the
public download is byte-exact (sha256 verified), and on a real
device that APK updated itself **from Hostinger alone** to bundle
1.0.3, with no GitHub involvement at any step.

### Database (phpMyAdmin)

The same API also covers the account's MySQL databases — the
backend leg next to the files:

```
sh scripts/hostinger-db.sh                    # list databases
sh scripts/hostinger-db.sh --phpmyadmin <db>  # open phpMyAdmin
```

- **List** — `GET /accounts/<user>/databases` returns each database,
  its user, host and permissions.
- **phpMyAdmin** — there is no shell or direct connection from the
  API; instead it mints a **one-time sign-on link** that opens an
  authenticated phpMyAdmin session in the browser. The link is a
  session credential: the script passes it straight to the browser
  and never prints it. Exporting a `.sql` dump is done in the
  phpMyAdmin UI (Export tab) — the API has no dump endpoint.

Tested live on the same account (2026-11-21): one database
(`u886742668_iWo5l5auTiXo5C`), the sign-on opened **phpMyAdmin
5.2.2** with its 6 tables listed. Read-only test — nothing in the
database was changed.

## Build the APK

Requirements: JDK 21, Android SDK platform 35 + build-tools 35.0.0
(build-tools 34.0.0 must also be present — AGP looks for it),
Node 20+.

```
npm install
npm run apk:debug
```

The debug APK lands at
`android/app/build/outputs/apk/debug/app-debug.apk`
(debug-signed, installable on any device with USB debugging or by
sideloading). For a store/release build, add your signing config and
run `./gradlew assembleRelease` in `android/`.

## Build for iPhone (iOS)

The iOS platform is generated and committed in `ios/` (Xcode project,
bundle ID `com.aeliteestrangeira.capacitorblanktemplate`, the house
icon as the 1024×1024 App Icon, the updater plugin wired). Live
updates work exactly as on Android — same bundle, same channel.

Compiling and signing an iOS app requires **macOS with Xcode**; that
step cannot run on Linux or Windows. On a Mac:

```
npm install
npx cap sync ios
cd ios/App && pod install
open App.xcworkspace
```

In Xcode: select your development team (Signing & Capabilities),
then Run on a device or Product → Archive for TestFlight/App Store.
Installing on real iPhones outside the simulator requires an Apple
Developer Program account (paid) — provisioning and signing are
handled by Xcode with your Apple ID.

No Mac at hand? The `ios-build.yml` workflow builds the app on a
GitHub-hosted **macOS runner** (push or manual dispatch) and
packages an **unsigned device IPA**, attached to the v1.0.1 release
as `capacitor-blank-template-1.0.1-ios-unsigned.ipa`. Unsigned means
an iPhone will not install it until it is signed with an Apple
Developer account — it is the real compiled app, ready for that
signature.

## Ship an interface update (no new APK)

1. Edit `www/` and bump `"version"` in `www/version.json` (the
   bundle's single source of truth; put a one-line "what's new" in
   its `notes` — the interface shows it after the update).
2. `npm run bundle` — regenerates `release/bundle.zip` and
   `release/latest.json`.
3. Publish a GitHub release for the new version with those two files
   as assets, keeping the asset names exactly `bundle.zip` and
   `latest.json`.
4. Installed apps pick the update up on the next launch (or from the
   Updates panel's check button) and reload into the new bundle.

## Publishing to the stores

`store/` holds the backend scaffolding for both stores — the
credential slots, templates and fastlane lanes for Google Play
(service account JSON + upload keystore) and the App Store
(App Store Connect API key: Key ID, Issuer ID, `.p8`). Real
credential files are git-ignored by design; see `store/README.md`
for where each piece comes from and the order to fill them in.

## House rules baked in

- The launcher icon is generated from the house mark at every density
  (legacy, round and adaptive), background `#0F1115`.
- No credentials in the repository, ever; publishing uses a token
  from the environment only.
- Copyright is always **A Elite Estrangeira**.

## Rebuild from scratch (after a format)

The numbered PowerShell scripts in `scripts/` (`01`–`05`, alongside
the bundle utilities) rebuild the whole build machine on a freshly
formatted Windows PC: each script verifies its own step and aborts
on failure.

**Environment contract:** Windows 10/11 x64, internet access, winget
(App Installer) present, about 6 GB free. No accounts or credentials
are needed to build and install the APK — the repository is public.

**Drive choice:** every script takes a mandatory `-Drive` parameter
on purpose — drive letters change per machine. Node.js, the JDK, the
Android SDK, the clone and the builds all live on the chosen drive
(`<Drive>:\nodejs`, `<Drive>:\jdk-21`, `<Drive>:\Android\Sdk`,
`<Drive>:\CapacitorTemplate`). Install on an **internal** disk: on
the reference machine that is `F:`, an internal 1 TB HDD that is
always attached.

| Step | Script | What it proves |
| --- | --- | --- |
| 1 | `scripts/01-install-prerequisites.ps1` | Git installs; Node.js **26.13.0** lands on the chosen drive, verified by exact size + SHA256 from the official SHASUMS256; Microsoft OpenJDK **21.0.13.1** (Capacitor 7 requires JDK 21 — 17 fails) and the Android SDK (platform 35, build-tools **35.0.0 and 34.0.0** — AGP needs both — platform-tools) install from the official hosts, verified by exact size, with licenses accepted and `JAVA_HOME`/`ANDROID_HOME` set. |
| 2 | `scripts/02-clone-and-install.ps1` | The repository clones (or updates) and `npm install` completes with the Capacitor CLI and the Capgo updater present. |
| 3 | `scripts/03-build-apk.ps1` | `cap sync android` plus the Gradle wrapper produce `app-debug.apk`. On a normal machine the wrapper downloads Gradle and the dependencies itself — no offline workaround is needed (that was specific to one sandboxed VM). |
| 4 | `scripts/04-install-on-device.ps1` | With a device connected (USB debugging) or an emulator running, `adb install` lands the package and its `versionName` reads back from the device. |
| 5 | `scripts/05-run-smoke-tests.ps1` | The toolchain answers, **both** update channels (GitHub and Hostinger `latest.json`) respond and parse, the app launches on a connected device (skipped, not failed, without one), and a record file lands on the Desktop. |

Standalone checks live in `tests/`: `01-update-channels-check.ps1`
(both manifests, complete with checksums) and
`02-toolchain-check.ps1` (Node, JDK 21, SDK components).

Honest status: every fact in these scripts was proven when the
template was built — the APK was compiled and installed, and both
channels delivered updates to a real phone (1.0.3 → 1.0.4 → 1.0.5).
The `.ps1` files are faithful transcriptions of that procedure for a
standard Windows machine and have not yet been executed as files; a
full from-format run is the real test, exactly as with any rebuild
kit.

## License

Copyright (c) 2026 A Elite Estrangeira. All rights reserved. See
[LICENSE](LICENSE).
