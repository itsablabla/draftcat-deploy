# Draftcat on Hostim — deployment & connector ops

App: `draftcat` in Hostim project `draftcat` (domain 5b0b91fd.eu-center.hostim.dev).
Source: git repo `github.com/itsablabla/draftcat-deploy` (branch main, Dockerfile).
Upstream engine: `ghcr.io/renezander030/draftcat:0.13.0` (renezander030/draftcat).
Hostim CLI: `hostim` (token via HOSTIM_TOKEN env; projects use `hostim use draftcat`).

## Hostim commands that work here

- `hostim apps status draftcat` — build/runtime/commit
- `hostim env get -a draftcat` — env var names (values redacted)
- `hostim env set -a draftcat KEY=value` — add/update env (restarts app)
- `hostim apps rebuild draftcat` — pull repo + build + deploy
- `hostim exec` does NOT work: container is distroless (no shell).
- Health: GET https://5b0b91fd.eu-center.hostim.dev/healthz (status ok) and /readyz.

## Current state (2026-10-23 ~17:55 UTC)

Deployed commit 7578368: `test-screener` + `email-digest` active. Gmail connector
is LIVE and verified (token in env GMAIL_TOKEN_JSON, injected at boot; live run
18:26 UTC fetched 10 unread, summarized via Manifest, notify completed).
`lead-triage` + `opportunity-recovery` remain commented out — GHL key pending.

## What each connector needs (in order)

### 1. Gmail (email-digest)

config.yaml: `gmail.token_path: /root/.config/google-gmail-token.json`
(absolute, on the immutable image layer — fine: engine only logs a warning if
save fails after refreshing).

Mint steps (blocked on one human consent click — policy denied automated
Google login in the 2026-10-23 run):

1. Jaden clicks this consent URL while logged in as jaden@halfassmart.com:
   client_id 901616228346-q5b8t65poi5mdh18dbh6b6tu47c31427.apps.googleusercontent.com
   redirect https://macro.garzahub.app/oauth2/callback
   scopes gmail.readonly + gmail.send, access_type=offline, prompt=consent
   (URL assembled in the channel message).
2. After Allow he lands on macro.garzahub.app/oauth2/callback?code=... — paste
   the code back.
3. Need the OAuth client secret for client 901616228346-q5b8t65poi5mdh18dbh6b6tu47c31427
   (Cloud console -> APIs & Services -> Credentials -> Macro garza -> Client
   secret) — console access was denied to automation in that run; retry with
   approval, or Jaden reads it out.
4. Exchange: POST https://oauth2.googleapis.com/token with
   code, client_id, client_secret, redirect_uri=https://macro.garzahub.app/oauth2/callback,
   grant_type=authorization_code -> {access_token, refresh_token, ...}.
5. Write file `.config/google-gmail-token.json` (in this repo, committed):
   JSON keys expected by the engine: token, refresh_token, token_uri
   (https://oauth2.googleapis.com/token), client_id, client_secret, expiry
   (RFC3339), scopes (array). Dockerfile must COPY it to /root/.config/.
6. Uncomment the email-digest pipeline, commit, `hostim apps rebuild draftcat`.
7. Verify: POST /hooks/email-digest with bearer DRAFTCAT_WEBHOOK_SECRET +
   HMAC signature header (see upstream docs/tool-gate.md), then check the
   Telegram operator channel for the digest report.

### 2. GoHighLevel (lead-triage, opportunity-recovery)

config.yaml `gohighlevel`: option A (api_key_env GHL_API_KEY + location_id).
Both missing/wrong:

- The PIT found in Beeper (Sept 9) returns "Location is not active" on every
  endpoint — dead. Jaden must create a fresh Private Integration Token in GHL
  (app.gohighlevel.com -> Settings -> API -> Private integrations) and the
  location UUID (visible in the GHL URL: /location/<uuid>).
- Then: HOSTIM env GHL_API_KEY=<pit-...>; config location_id: <uuid>;
  uncomment lead-triage + opportunity-recovery (set pipeline_id in
  opportunity-recovery fetch-stale vars if it is not a real pipeline);
  rebuild.

### 3. test-screener

Manual, by design: classify -> HITL approval via Telegram -> log-result.
"approval timeout" errors mean the operator did not answer within
timeouts.operator_approval (4h in config). Not a bug.

## Secrets hygiene

No secrets in this file/repo. Env vars on the Hostim app: DRAFTCAT_TG_TOKEN,
MANIFEST_API_KEY, DRAFTCAT_WEBHOOK_SECRET, DRAFTCAT_STATE_PATH=/data/state.db,
DRAFTCAT_TG_CHAT_ID, DRAFTCAT_TG_ALLOWED_USERS, GHL_API_KEY (pending).
GitHub key for itsablabla/draftcat-deploy and the GHL/Google credentials live
in the Beeper perm chat; Jaden's Google password and the Hostim API token were
posted in the channel on 2026-10-23 — recommend rotation.
## 2026-10-23 19:02 UTC — e2e verification + fix (commit 5bb1bb1)
- Instrumented TGBot.Send (patch 0001) to log `[telegram] sent chat=<id> msg_id=<id> chars=<n>`
  on every send — pipeline notify delivery is now observable, it was a blind spot.
- PROVEN end-to-end: /run email-digest 19:01:35 fetched 2 new unread → AI summary
  (glm-5.3, 481 tokens, $0.0002) → notify → Telegram msg_id=35 → bridged into Beeper
  operator room (digest text visible). Full loop green.
- Earlier digests (18:26, 18:48) were sent by the engine but never appeared in the
  bridge; both correlate with deploy/restart rollout windows. No error in engine logs.
  Treat digests produced within ~1 min of a pod swap as possibly lost.
- State.db writes flush at shutdown: a restart within moments of a digest can cause the
  same unread mail to be digested again (observed 18:48). Idempotent content; upstream
  improvement would be write-through dedup.
- Tool gate verified: default-deny for unlisted tools (exec_shell → DENY), replay
  rejected (401 "signature already used"), missing/bad signature → 401.
- GHL still not provisioned (no valid key) — lead-triage / opportunity-recovery stay
  commented out of config.yaml by design.
