#!/bin/sh
# Publishes the live-update channel to a Hostinger hosting account.
#
# Uploads bundle.bin first and latest.json last, so the manifest never
# points at a bundle that is not there yet, then verifies the public
# URLs and the bundle's sha256 against the manifest.
#
# Configuration (environment variables):
#   HOSTINGER_HELPER   path to the hostinger_aelite.py helper
#                      (default: the A Elite Estrangeira connector)
#   HOSTINGER_BASE_URL public URL of the target folder
#                      (default: https://aeliteestrangeira.com/capacitor-updates)
#   HOSTINGER_DIR      folder inside public_html
#                      (default: capacitor-updates)
#
# Usage: sh scripts/deploy-hostinger.sh
set -e

HELPER="${HOSTINGER_HELPER:-$HOME/workspace/custom-connectors/custom.hostinger-aelite/bin/hostinger_aelite.py}"
BASE_URL="${HOSTINGER_BASE_URL:-https://aeliteestrangeira.com/capacitor-updates}"
DIR="${HOSTINGER_DIR:-capacitor-updates}"
cd "$(dirname "$0")/.."

VERSION="$(python3 -c "import json; print(json.load(open('www/version.json'))['version'])")"
BUNDLE_NAME="bundle-$VERSION.bin"

echo "== building the bundle (manifest -> $BASE_URL/$BUNDLE_NAME)"
BUNDLE_URL="$BASE_URL/$BUNDLE_NAME" npm run bundle

# The bundle goes under a VERSIONED name: the hosting CDN caches
# binaries at their clean URL, so re-uploading a fixed bundle.bin
# would keep serving the first version. latest.json is not cached
# (no-store) and always points at the current versioned bundle.
echo "== uploading $BUNDLE_NAME"
python3 "$HELPER" upload release/bundle.bin "$DIR/$BUNDLE_NAME"

echo "== uploading latest.json"
python3 "$HELPER" upload release/latest.json "$DIR/latest.json"

echo "== verifying the public channel"
curl -s "$BASE_URL/latest.json"
CHECKSUM="$(python3 -c "import json; print(json.load(open('release/latest.json'))['checksum'])")"
DOWNLOADED="$(curl -s "$BASE_URL/$BUNDLE_NAME" | sha256sum | awk '{print $1}')"
echo "manifest checksum: $CHECKSUM"
echo "downloaded sha256: $DOWNLOADED"
[ "$CHECKSUM" = "$DOWNLOADED" ] && echo "OK: channel live and byte-exact" || {
  echo "MISMATCH: the downloaded bundle does not match the manifest"
  exit 1
}
