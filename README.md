# draftcat-deploy

Hostim deployment wrapper for [renezander030/draftcat](https://github.com/renezander030/draftcat).

The upstream image bakes its default `config.yaml` (OpenRouter provider) in at
`/work/config.yaml`. This repo ships a replacement `config.yaml` that points
Draftcat at the **Manifest** LLM gateway:

- `provider.base_url: https://app.manifest.build/v1`
- `provider.api_key_env: MANIFEST_API_KEY` (credential stays in Hostim env)
- `models.*.model: auto` (Manifest router picks the real model)
- `usage_accounting: false` (non-OpenRouter endpoint)

Everything else is byte-identical to upstream `config.yaml` at v0.13.0.

## Build

```dockerfile
FROM ghcr.io/renezander030/draftcat:0.13.0
COPY config.yaml /work/config.yaml
```

## Environment (set on the Hostim app, never committed)

- `DRAFTCAT_TG_TOKEN` — Telegram bot token
- `MANIFEST_API_KEY` — Manifest agent key
- `DRAFTCAT_STATE_PATH=/data/state.db` — persisted SQLite state (mounted volume)
