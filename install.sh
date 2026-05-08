#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-Mrzhiyao/cliproxyapi-usage-restore}"
TAG="${TAG:-v6.10.8-usage-restore.6}"
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
  install -m 0644 "${TMP_DIR}/config.yaml" "${CONFIG_FILE}"
  echo "Set remote-management.disable-auto-update-panel=true in ${CONFIG_FILE}"
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
