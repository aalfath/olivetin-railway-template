#!/usr/bin/env bash
# Used by the starter config's "Replace config.yaml" action (admins only).
# Reads the new config from $NEW_CONFIG, checks that OliveTin can load it,
# keeps the old file as config.yaml.bak and swaps the new one in. OliveTin
# notices the change and reloads by itself.
set -euo pipefail
CONFIG=/config/config.yaml
if [ -z "${NEW_CONFIG:-}" ]; then echo "The new config is empty: nothing changed."; exit 1; fi
CHECK=$(mktemp -d)
trap 'rm -r "$CHECK"' EXIT
printf '%s\n' "$NEW_CONFIG" > "$CHECK/config.yaml"
OUT=$(cd "$CHECK" && env -u PORT /usr/bin/OliveTin -configdir "$CHECK" -syntaxcheck 2>&1 || true)
if printf '%s' "$OUT" | grep -q "Configuration load failed" || ! printf '%s' "$OUT" | grep -q "configuration issues found"; then
  echo "OliveTin could not load the new config, so nothing changed:"
  printf '%s\n' "$OUT"
  exit 1
fi
if ! grep -Eq '^authRequireGuestsToLogin:[[:space:]]*true' "$CHECK/config.yaml"; then
  echo "The new config doesn't contain 'authRequireGuestsToLogin: true'. This OliveTin is on the"
  echo "public internet, so this action refuses configs that let guests in. Nothing changed."
  echo "(If you really want that, edit /config/config.yaml with 'railway ssh'.)"
  exit 1
fi
cp "$CONFIG" "$CONFIG.bak"
cat "$CHECK/config.yaml" > "$CONFIG"
echo "config.yaml replaced (previous copy: config.yaml.bak). OliveTin reloads it now."
echo "Syntax check report:"
printf '%s\n' "$OUT" | grep -v "^Found config file\|^Config file not found" || true
