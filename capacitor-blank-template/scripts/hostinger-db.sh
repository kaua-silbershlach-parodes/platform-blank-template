#!/bin/sh
# Hostinger database support: list the account's MySQL databases and
# open phpMyAdmin through the API's one-time sign-on link.
#
# The sign-on link is a session credential: this script never prints
# it. It travels from the API response to a 0600 temp file, straight
# into the browser opener, and the file is deleted right after.
#
# Configuration (environment variables):
#   HOSTINGER_HELPER   path to the hostinger_aelite.py helper
#                      (default: the A Elite Estrangeira connector)
#   HOSTINGER_USERNAME hosting account username (default: u886742668)
#
# Usage:
#   sh scripts/hostinger-db.sh                  # list databases
#   sh scripts/hostinger-db.sh --phpmyadmin DB  # open phpMyAdmin for DB
set -e

HELPER="${HOSTINGER_HELPER:-$HOME/workspace/custom-connectors/custom.hostinger-aelite/bin/hostinger_aelite.py}"
USERNAME="${HOSTINGER_USERNAME:-u886742668}"

if [ "$1" = "--phpmyadmin" ]; then
  DB="$2"
  [ -n "$DB" ] || { echo "usage: hostinger-db.sh --phpmyadmin <database>"; exit 1; }
  TMP="$(mktemp)"
  chmod 600 "$TMP"
  python3 "$HELPER" raw GET "/api/hosting/v1/accounts/$USERNAME/databases/$DB/phpmyadmin-link" > "$TMP.raw"
  python3 - "$TMP.raw" "$TMP" <<'PYEOF'
import json, sys
d = json.load(open(sys.argv[1]))
def find_url(o):
    if isinstance(o, str) and o.startswith('http'):
        return o
    if isinstance(o, dict):
        for v in o.values():
            r = find_url(v)
            if r:
                return r
    if isinstance(o, list):
        for v in o:
            r = find_url(v)
            if r:
                return r
    return None
url = find_url(d.get('result', {}))
assert url, 'no sign-on link in the API response'
open(sys.argv[2], 'w').write(url)
PYEOF
  rm -f "$TMP.raw"
  echo "opening phpMyAdmin for $DB (one-time sign-on, link not shown)"
  if command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$(cat "$TMP")"
  elif command -v open >/dev/null 2>&1; then
    open "$(cat "$TMP")"
  else
    echo "no browser opener found on this system" >&2
    rm -f "$TMP"
    exit 1
  fi
  rm -f "$TMP"
else
  python3 "$HELPER" raw GET "/api/hosting/v1/accounts/$USERNAME/databases"
fi
