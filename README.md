# CLIProxyAPI 6.10.8 Usage Restore

This package keeps the newer CLIProxyAPI `6.10.8` features, including GPT 5.5, and restores the old built-in CPAMC Usage Statistics page.

## What is included

- `cli-proxy-api-linux-amd64`: patched CLIProxyAPI `6.10.8-usage`
- `management.html`: current CPAMC frontend with the old Usage page restored
- `/v0/management/usage`, `/usage/export`, `/usage/import`: restored backend endpoints
- Management panel API calls (`/v0/management/api-call`) are counted when the upstream response includes usage/token fields
- Root OpenAI-compatible aliases (`/models`, `/chat/completions`, `/responses`) for clients that omit `/v1` in their base URL
- Installer adds `cpa55-*` GPT-5.5 aliases and reasoning overrides to `config.yaml`
- Cursor BYOK compatibility for GPT-5 family requests where a Responses API payload is sent to `/v1/chat/completions`
- Cursor old-chat compatibility for overlong tool `call_id` values in both Responses payloads and Chat Completions histories
- Cursor compatibility for clients that send OpenAI `metadata` to the Codex/OAuth upstream
- `install.sh`: one-command installer for existing Linux deployments

## Quick Install

Run this on a server that already has CLIProxyAPI installed at `/home/admin/cliproxyapi` with service `proxy.service`:

```bash
curl -fsSL https://github.com/Mrzhiyao/cliproxyapi-usage-restore/releases/latest/download/install.sh | bash
```

Custom path or service name:

```bash
curl -fsSL https://github.com/Mrzhiyao/cliproxyapi-usage-restore/releases/latest/download/install.sh \
  | APP_DIR=/home/admin/cliproxyapi SERVICE=proxy.service bash
```

## Usage Page

After installation, open:

```text
http://YOUR_SERVER:8318/management.html#/usage
```

The sidebar entry is `Usage`.

## Notes

- This restores the old in-memory usage aggregation. Usage data starts from process start unless you import a previous export.
- Existing files are backed up before replacement.
- The installer sets `remote-management.disable-auto-update-panel: true` so the restored panel is not overwritten by upstream auto-update.
- The installer does not copy your private OAuth/auth files or API keys from another server. Configure `api-keys` and OAuth login/auth files on each server, or copy them yourself.
- Make sure `usage-statistics-enabled: true` is enabled.

## Changelog

### v6.10.8-usage-restore.9

- Stripped unsupported OpenAI `metadata` before forwarding GPT-5.5/Codex OAuth requests upstream.
- Keeps the root `/models` aliases, `cpa55-*` installer aliases, usage page restore, and long `call_id` compatibility fixes.

### v6.10.8-usage-restore.8

- Added root OpenAI-compatible route aliases for `/models`, `/chat/completions`, `/completions`, and `/responses`.
- Updated installer to add `cpa55-*` GPT-5.5 aliases and reasoning overrides to `config.yaml`.
- Clarified that OAuth/auth files and API keys are per-server credentials and are not bundled in the release.

### v6.10.8-usage-restore.7

- Added Cursor old-chat compatibility for long tool `call_id` values in Chat Completions histories.
- Keeps the Usage page restore, GPT-5.5 aliases, Cursor BYOK shim, and API-call usage counting.

### v6.10.8-usage-restore.6

- Expanded old-chat compatibility so overlong Responses API `call_id` values are shortened even in large restored histories with `previous_response_id`.
- Keeps the Usage page restore and Cursor BYOK GPT-5 shims.

### v6.10.8-usage-restore.5

- Added Cursor old-chat compatibility for overlong Responses API tool `call_id` values.
- Keeps the restored CPAMC Usage page, Cursor BYOK GPT-5 shim, and API-call usage counting.

### v6.10.8-usage-restore.4

- Added a Cursor BYOK compatibility shim for GPT-5 family requests where a Responses API payload is sent to `/v1/chat/completions`.
- Keeps the restored CPAMC Usage page and API-call usage counting.

### v6.10.8-usage-restore.3

- Counted management panel API calls through `/v0/management/api-call` when upstream responses include usage/token fields.
- Kept the restored Usage / 使用统计 frontend and backend endpoints.
- Installer still disables CPAMC panel auto-update to prevent the restored page being overwritten.

### v6.10.8-usage-restore.2

- Kept the same CLIProxyAPI `6.10.8` usage restore build.
- Updated installer to set `remote-management.disable-auto-update-panel: true`.

### v6.10.8-usage-restore.1

- Restored the old CPAMC Usage Statistics page.
- Restored `/v0/management/usage` endpoints on top of CLIProxyAPI `6.10.8`.
- Kept GPT-5.5 support from the newer backend.

## Source

This is a compatibility build made from:

- Backend: `router-for-me/CLIProxyAPI` `v6.10.8`
- Frontend: `router-for-me/Cli-Proxy-API-Management-Center`, with the Usage page restored from before the upstream removal
