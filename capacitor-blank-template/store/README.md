# Store publishing — backend scaffolding

Everything needed to publish this app to **Google Play** and the
**Apple App Store** lives here, ready to be filled in. This is
backend/configuration only — nothing in this folder appears in the
app's interface.

**Security rule:** the real credential files are listed in the root
`.gitignore` and must never be committed. Only the `*.example.*`
files are templates. Keep the real files in a password manager /
vault; anyone holding them can publish as you.

## Google Play

Account: Google Play Developer account — **US$ 25, one time**
(play.google.com/console). Publishing by API additionally needs:

| Piece | What it is | Where it comes from |
| --- | --- | --- |
| Service account | A machine user, e.g. `play-publisher@<project>.iam.gserviceaccount.com` | Google Cloud Console → IAM & Admin → Service Accounts (project linked to Play Console, **Google Play Android Developer API** enabled) |
| `service-account.json` | The service account's JSON key — a full credential | Same page → Keys → Add Key → JSON (downloaded once; Google keeps no copy). Save it here as `store/google-play/service-account.json`, following `service-account.example.json` |
| Play Console grant | The service account must be invited with release permissions | Play Console → Users and permissions → Invite the service account e-mail (Release manager, or Manage production/testing releases) |
| Upload key | The keystore (`.jks`) that signs the AAB you upload; Google holds the final app-signing key (Play App Signing) | Generate once with `keytool` (see below); signing is wired via `keystore.properties` (template below) |

Notes from Google's rules: the **first** release of an app must be
uploaded manually in Play Console before API uploads work on that
track, and **new personal accounts must complete a closed-testing
period before production access** — check Play Console for the
current requirement.

Generate the upload keystore once (keep the file and passwords in
your vault — losing it means contacting Google to reset it):

```
keytool -genkeypair -v -keystore store/google-play/upload-keystore.jks \
  -alias upload -keyalg RSA -keysize 2048 -validity 10000
```

And `android/keystore.properties` (also git-ignored):

```
storeFile=../../store/google-play/upload-keystore.jks
storePassword=…
keyAlias=upload
keyPassword=…
```

## Apple App Store

Account: Apple Developer Program — **US$ 99 / year**
(developer.apple.com). Publishing by API (fastlane / App Store
Connect API) needs a **team API key** — three pieces from one page:

| Piece | What it is | Where it is |
| --- | --- | --- |
| Issuer ID | UUID identifying your team, same for all team keys | App Store Connect → Users and Access → Integrations → App Store Connect API (above the keys table) |
| Key ID | 10 characters, one per key | Same page, in the key's row |
| `AuthKey_<KeyID>.p8` | The private key file | **Download API Key on that page — offered exactly once.** Save it here as `store/app-store/AuthKey_<KeyID>.p8` |

Save the three values in `store/app-store/appstore-connect.json`,
following `appstore-connect.example.json`. Choose the **App Manager**
role for the key (Admin also works). Signing certificates and
provisioning profiles are managed by Xcode / fastlane on a Mac with
your Apple ID and Team ID.

## Publishing lanes (fastlane)

`store/fastlane/` holds a starter `Appfile` + `Fastfile`:

- `fastlane android internal` — builds the release AAB and uploads
  it to the Play **internal** track, using
  `store/google-play/service-account.json`.
- `fastlane ios beta` — builds the iOS app and uploads it to
  **TestFlight**, using `store/app-store/appstore-connect.json`.
  Runs on macOS only.

Install fastlane from fastlane.tools. Both lanes fail until the
credential files above exist — that is expected; the scaffolding is
the point.
