# draftcat-deploy

Hostim deployment wrapper for [renezander030/draftcat](https://github.com/renezander030/draftcat).

The upstream image bakes its default `config.yaml` (OpenRouter provider) in at
`/work/config.yaml`. This repo ships a replacement `config.yaml` that:

- points the provider at the **Manifest** LLM gateway
  (`base_url: https://app.manifest.build/v1`, `api_key_env: MANIFEST_API_KEY`,
  model `auto`, `usage_accounting: false`);
- **enables the webhook listener** (0.0.0.0:8088): `/healthz`, `/readyz`,
  `/hooks/<pipeline>`, and the tool-call gate `/gate/tool-call`;
- **enables the tool gate** with an allowlist for the operator agent stack
  (web search/fetch + KERNEL browser/webmcp calls allowed + audited;
  `send_email`, `send_message`, `post_to_channel`, `refund` require
  operator approval). Default deny for anything unlisted.

## Build

```dockerfile
FROM ghcr.io/renezander030/draftcat:0.13.0
COPY config.yaml /work/config.yaml
```

## Environment (set on the Hostim app, never committed)

- `DRAFTCAT_TG_TOKEN` — Telegram bot token
- `MANIFEST_API_KEY` — Manifest agent key
- `DRAFTCAT_WEBHOOK_SECRET` — bearer token for `/hooks/*` and `/gate/tool-call`
  (required while `webhook.enabled`; HMAC signature `t=<unix>,v1=...` also
  required, see upstream docs/tool-gate.md)
- `DRAFTCAT_STATE_PATH=/data/state.db` — persisted SQLite state (mounted volume)
- `DRAFTCAT_TG_ALLOWED_USERS` / `DRAFTCAT_TG_CHAT_ID` — operator Telegram user
  ID(s); without them the bot starts but no operator is bound
- `GMAIL_TOKEN_JSON` — base64 Gmail OAuth token JSON (decoded to /root/.config/google-gmail-token.json by the entrypoint)
