#!/usr/bin/env bash
# proxmox/dev/down.sh
set -euo pipefail

DEV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$DEV_DIR/compose.yml"
ENV_FILE="$DEV_DIR/.env"

docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" down -t 0 --remove-orphans --volumes || true
echo "[dev-down] Stopped"
