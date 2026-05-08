# CLIProxyAPI 6.10.8 Usage Restore

This package keeps the newer CLIProxyAPI `6.10.8` features, including GPT 5.5, and restores the old built-in CPAMC Usage Statistics page.

## What is included

- `cli-proxy-api-linux-amd64`: patched CLIProxyAPI `6.10.8-usage`
- `management.html`: current CPAMC frontend with the old Usage page restored
- `/v0/management/usage`, `/usage/export`, `/usage/import`: restored backend endpoints
- Management panel API calls (`/v0/management/api-call`) are counted when the upstream response includes usage/token fields
- Cursor BYOK compatibility for GPT-5 family requests where a Responses API payload is sent to `/v1/chat/completions`
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
- Make sure `usage-statistics-enabled: true` is enabled.

## Source

This is a compatibility build made from:

- Backend: `router-for-me/CLIProxyAPI` `v6.10.8`
- Frontend: `router-for-me/Cli-Proxy-API-Management-Center`, with the Usage page restored from before the upstream removal
