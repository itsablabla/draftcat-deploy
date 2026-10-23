#!/bin/sh
# Draftcat container entrypoint.
# If a Gmail token JSON is provided (base64) via GMAIL_TOKEN_JSON, decode it to
# the path config.yaml points at (gmail.token_path) before starting the engine.
TOKEN_PATH=/root/.config/google-gmail-token.json
if [ -n "$GMAIL_TOKEN_JSON" ]; then
  mkdir -p "$(dirname "$TOKEN_PATH")"
  printf '%s' "$GMAIL_TOKEN_JSON" | base64 -d > "$TOKEN_PATH"
  chmod 600 "$TOKEN_PATH"
fi
exec /usr/local/bin/draftcat
