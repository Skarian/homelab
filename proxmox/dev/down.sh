#!/usr/bin/env bash
set -euo pipefail

DEV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$DEV_DIR/compose.yml"

docker compose -f "$COMPOSE_FILE" down -t 0 --remove-orphans --volumes || true
echo "[dev-down] Stopped"
