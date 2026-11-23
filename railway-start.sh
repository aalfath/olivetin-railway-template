#!/usr/bin/env bash
# Railway start script for OliveTin.
# - /config is the Railway volume: config.yaml, login sessions, saved action logs, $HOME.
# - The first boot writes a starter config.yaml that forces login. After that the
#   file is yours: it is never overwritten.
# - The admin password comes from OLIVETIN_ADMIN_PASSWORD. It is hashed (argon2id)
#   on every boot by a throwaway OliveTin on 127.0.0.1 and handed to the config
#   as ${{ OLIVETIN_ADMIN_PASSWORD_HASH }}, so the hash never lands on disk and a
#   new password only needs a redeploy.
set -euo pipefail

CONFIG_DIR=/config
OT_UID=1000
OT_GID=999

log() { echo "railway-start: $*"; }

if [ -z "${OLIVETIN_ADMIN_PASSWORD:-}" ]; then
  log "OLIVETIN_ADMIN_PASSWORD is empty. Set it in the service variables (the template generates one) and redeploy." >&2
  exit 1
fi
export OLIVETIN_ADMIN_USERNAME="${OLIVETIN_ADMIN_USERNAME:-admin}"
export PORT="${PORT:-1337}"
export HOME="$CONFIG_DIR/home"

mkdir -p "$CONFIG_DIR" "$CONFIG_DIR/logs" "$HOME"
if [ ! -f "$CONFIG_DIR/config.yaml" ]; then
  log "no config.yaml on the volume yet, writing the starter config (login required)"
  cp /opt/railway/config.default.yaml "$CONFIG_DIR/config.yaml"
fi
# Saved action logs older than 30 days are removed so the volume doesn't fill up.
find "$CONFIG_DIR/logs" -type f -mtime +30 -delete 2>/dev/null || true
chown -R "$OT_UID:$OT_GID" "$CONFIG_DIR"
chmod 0700 "$HOME"

as_olivetin() { setpriv --reuid="$OT_UID" --regid="$OT_GID" --clear-groups -- "$@"; }

# Hash the admin password with OliveTin's own PasswordHash API.
HASH_DIR=$(mktemp -d)
HASH_PORT=18337
cat > "$HASH_DIR/config.yaml" <<YAML
listenAddressSingleHTTPFrontend: 127.0.0.1:$HASH_PORT
logLevel: WARN
checkForUpdates: false
actions: []
YAML
chown -R "$OT_UID:$OT_GID" "$HASH_DIR"
( cd "$HASH_DIR" && env -u PORT HOME="$HASH_DIR" setpriv --reuid="$OT_UID" --regid="$OT_GID" --clear-groups -- \
    /usr/bin/OliveTin -configdir "$HASH_DIR" >"$HASH_DIR/out.log" 2>&1 ) &
HASH_PID=$!
OLIVETIN_ADMIN_PASSWORD_HASH=$(HASH_PORT=$HASH_PORT python3 - <<'PY'
import json, os, sys, time, urllib.request
url = "http://127.0.0.1:%s/api/PasswordHash" % os.environ["HASH_PORT"]
body = json.dumps({"password": os.environ["OLIVETIN_ADMIN_PASSWORD"]}).encode()
last = None
for _ in range(120):
    try:
        req = urllib.request.Request(url, data=body, headers={"Content-Type": "application/json"})
        h = json.load(urllib.request.urlopen(req, timeout=10)).get("hash", "")
        if h.startswith("$argon2id$"):
            print(h)
            sys.exit(0)
        last = "unexpected response"
    except Exception as e:  # not up yet
        last = e
    time.sleep(0.5)
print("could not hash the admin password: %s" % last, file=sys.stderr)
sys.exit(1)
PY
) || { log "password hashing failed; helper log:" >&2; cat "$HASH_DIR/out.log" >&2; kill "$HASH_PID" 2>/dev/null || true; exit 1; }
kill "$HASH_PID" 2>/dev/null || true
wait "$HASH_PID" 2>/dev/null || true
rm -r "$HASH_DIR"
export OLIVETIN_ADMIN_PASSWORD_HASH
log "admin password hashed; starting OliveTin on port $PORT as user '$OLIVETIN_ADMIN_USERNAME'"

unset OLIVETIN_ADMIN_PASSWORD
cd "$CONFIG_DIR"
exec setpriv --reuid="$OT_UID" --regid="$OT_GID" --clear-groups -- /usr/bin/OliveTin -configdir "$CONFIG_DIR"
