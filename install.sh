#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-Mrzhiyao/cliproxyapi-usage-restore}"
TAG="${TAG:-v6.10.8-usage-restore.9}"
APP_DIR="${APP_DIR:-/home/admin/cliproxyapi}"
SERVICE="${SERVICE:-proxy.service}"
CONFIG_FILE="${CONFIG_FILE:-${APP_DIR}/config.yaml}"

BASE_URL="https://github.com/${REPO}/releases/download/${TAG}"
TMP_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "missing required command: $1" >&2
    exit 1
  }
}

need_cmd curl
need_cmd sha256sum
need_cmd python3

if [ ! -d "${APP_DIR}" ]; then
  echo "APP_DIR does not exist: ${APP_DIR}" >&2
  exit 1
fi

if [ ! -d "${APP_DIR}/static" ]; then
  mkdir -p "${APP_DIR}/static"
fi

echo "Downloading CLIProxyAPI usage restore assets from ${REPO} ${TAG}..."
curl -fsSL "${BASE_URL}/cli-proxy-api-linux-amd64" -o "${TMP_DIR}/cli-proxy-api-linux-amd64"
curl -fsSL "${BASE_URL}/management.html" -o "${TMP_DIR}/management.html"
curl -fsSL "${BASE_URL}/checksums.sha256" -o "${TMP_DIR}/checksums.sha256"

(
  cd "${TMP_DIR}"
  sha256sum -c checksums.sha256
)

STAMP="$(date -u +%Y%m%d%H%M%S)"
if [ -f "${APP_DIR}/cli-proxy-api" ]; then
  cp "${APP_DIR}/cli-proxy-api" "${APP_DIR}/cli-proxy-api.bak.before-usage-restore.${STAMP}"
fi
if [ -f "${APP_DIR}/static/management.html" ]; then
  cp "${APP_DIR}/static/management.html" "${APP_DIR}/static/management.html.bak.before-usage-restore.${STAMP}"
fi

install -m 0755 "${TMP_DIR}/cli-proxy-api-linux-amd64" "${APP_DIR}/cli-proxy-api"
install -m 0644 "${TMP_DIR}/management.html" "${APP_DIR}/static/management.html"

if [ -f "${CONFIG_FILE}" ]; then
  cp "${CONFIG_FILE}" "${CONFIG_FILE}.bak.before-usage-restore.${STAMP}"
  awk '
    BEGIN { in_remote = 0; found_remote = 0; wrote = 0 }
    function write_setting() {
      print "  disable-auto-update-panel: true"
      wrote = 1
    }
    /^remote-management:[[:space:]]*$/ {
      found_remote = 1
      in_remote = 1
      print
      next
    }
    in_remote {
      if ($0 ~ /^[^[:space:]#][^:]*:/) {
        if (!wrote) {
          write_setting()
        }
        in_remote = 0
      } else if ($0 ~ /^[[:space:]]+disable-auto-update-panel:[[:space:]]*/) {
        if (!wrote) {
          write_setting()
        }
        next
      }
    }
    { print }
    END {
      if (in_remote && !wrote) {
        write_setting()
      }
      if (!found_remote) {
        print ""
        print "remote-management:"
        print "  disable-auto-update-panel: true"
      }
    }
  ' "${CONFIG_FILE}" > "${TMP_DIR}/config.yaml"
  python3 - "${TMP_DIR}/config.yaml" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text()
lines = text.splitlines()

alias_marker = "# CPA55 compatibility aliases (managed by usage-restore installer)"
alias_entries = """  - name: gpt-5.5
    alias: cpa55
    fork: true
  - name: gpt-5.5
    alias: cpa55-fast
    fork: true
  - name: gpt-5.5
    alias: cpa55-low
    fork: true
  - name: gpt-5.5
    alias: cpa55-medium
    fork: true
  - name: gpt-5.5
    alias: cpa55-high
    fork: true
  - name: gpt-5.5
    alias: cpa55-xhigh
    fork: true
  - name: gpt-5.5
    alias: cpa55-extra-high
    fork: true""".splitlines()

payload_marker = "  # CPA55 reasoning overrides (managed by usage-restore installer)"
payload_entries = """  - models:
    - name: cpa55-low
      protocol: codex
    - name: cpa55-fast
      protocol: codex
    params:
      "reasoning.effort": low
  - models:
    - name: cpa55-medium
      protocol: codex
    params:
      "reasoning.effort": medium
  - models:
    - name: cpa55-high
      protocol: codex
    params:
      "reasoning.effort": high
  - models:
    - name: cpa55-xhigh
      protocol: codex
    - name: cpa55-extra-high
      protocol: codex
    params:
      "reasoning.effort": xhigh""".splitlines()

top_level = re.compile(r"^[A-Za-z0-9_-][A-Za-z0-9_-]*:\s*(?:#.*)?$")

def section_bounds(name):
    start = None
    for i, line in enumerate(lines):
        if re.match(rf"^{re.escape(name)}:\s*(?:#.*)?$", line):
            start = i
            break
    if start is None:
        return None, None
    end = len(lines)
    for j in range(start + 1, len(lines)):
        if top_level.match(lines[j]):
            end = j
            break
    return start, end

def insert_at(idx, new_lines):
    lines[idx:idx] = new_lines

if "alias: cpa55-extra-high" not in "\n".join(lines):
    start, end = section_bounds("oauth-model-alias")
    block = [alias_marker]
    if start is None:
        lines.extend(["", "oauth-model-alias:", "  codex:"])
        lines.extend(alias_entries)
    else:
        codex_idx = None
        for i in range(start + 1, end):
            if re.match(r"^\s{2}codex:\s*(?:#.*)?$", lines[i]):
                codex_idx = i
                break
        if codex_idx is None:
            insert_at(end, block + ["  codex:"] + alias_entries)
        else:
            insert_at(codex_idx + 1, block + alias_entries)

joined = "\n".join(lines)
if payload_marker.strip() not in joined and "cpa55-extra-high" in joined:
    start, end = section_bounds("payload")
    block = [payload_marker] + payload_entries
    if start is None:
        lines.extend(["", "payload:", "  override:"] + block)
    else:
        override_idx = None
        for i in range(start + 1, end):
            if re.match(r"^\s{2}override:\s*(?:#.*)?$", lines[i]):
                override_idx = i
                break
        if override_idx is None:
            insert_at(end, ["  override:"] + block)
        else:
            insert_at(override_idx + 1, block)

path.write_text("\n".join(lines) + "\n")
PY
  install -m 0644 "${TMP_DIR}/config.yaml" "${CONFIG_FILE}"
  echo "Set remote-management.disable-auto-update-panel=true in ${CONFIG_FILE}"
  echo "Ensured cpa55 GPT-5.5 aliases and reasoning overrides in ${CONFIG_FILE}"
else
  echo "Config file not found at ${CONFIG_FILE}; skipped disabling panel auto update."
fi

if command -v systemctl >/dev/null 2>&1; then
  if [ "$(id -u)" -eq 0 ]; then
    systemctl restart "${SERVICE}"
    systemctl is-active "${SERVICE}"
  else
    sudo systemctl restart "${SERVICE}"
    sudo systemctl is-active "${SERVICE}"
  fi
else
  echo "systemctl not found; restart your CLIProxyAPI process manually."
fi

echo
echo "Installed CLIProxyAPI 6.10.8 usage restore."
echo "Open: http://YOUR_SERVER:8318/management.html#/usage"
