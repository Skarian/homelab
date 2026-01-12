#!/usr/bin/env bash
set -euo pipefail

# proxmox/bootstrap.sh
#
# Usage:
#   ./proxmox/bootstrap.sh root@<PVE_HOST> ~/.ssh/id_ed25519.pub [--create-token]
#
# Notes:
# - Pass a pubkey FILE path (recommended), not a raw pubkey string.
# - --create-token will create the token ONLY if it doesn't already exist.

PVE_HOST="${1:-}"
PUBKEY_FILE="${2:-}"
FLAG="${3:-}"

if [[ -z "$PVE_HOST" || -z "$PUBKEY_FILE" ]]; then
  echo "usage: $0 root@<PVE_HOST> <PUBKEY_FILE> [--create-token]" >&2
  exit 2
fi

if [[ ! -f "$PUBKEY_FILE" ]]; then
  echo "error: pubkey file not found: $PUBKEY_FILE" >&2
  exit 2
fi

if [[ -n "${FLAG:-}" && "$FLAG" != "--create-token" ]]; then
  echo "error: third arg must be --create-token (or omit it)" >&2
  exit 2
fi

PUBKEY="$(cat "$PUBKEY_FILE")"
PUBKEY_B64="$(printf '%s' "$PUBKEY" | base64 | tr -d '\n')"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REMOTE_SCRIPT="$SCRIPT_DIR/bootstrap.remote.sh"

if [[ ! -f "$REMOTE_SCRIPT" ]]; then
  echo "error: missing remote script: $REMOTE_SCRIPT" >&2
  exit 2
fi

echo "[local] Running bootstrap on $PVE_HOST"
echo "[local] Using pubkey: $PUBKEY_FILE"
echo "[local] Token create mode: ${FLAG:-<skip>}"

# No heredocs. Just ship the file over STDIN.
ssh "$PVE_HOST" "PUBKEY_B64='$PUBKEY_B64' CREATE_TOKEN='${FLAG:-}' bash -s" <"$REMOTE_SCRIPT"
