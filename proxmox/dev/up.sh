#!/usr/bin/env bash
# proxmox/dev/up.sh
set -euo pipefail

DEV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$DEV_DIR/compose.yml"
ENV_FILE="$DEV_DIR/.env"

# Resolve password with precedence:
# 1) environment variable PVE_ROOT_PASSWORD
# 2) proxmox/dev/.env (PVE_ROOT_PASSWORD=...)
# 3) default 123
PVE_ROOT_PASSWORD="${PVE_ROOT_PASSWORD:-}"
if [[ -z "${PVE_ROOT_PASSWORD}" && -f "$ENV_FILE" ]]; then
  PVE_ROOT_PASSWORD="$(grep -E '^PVE_ROOT_PASSWORD=' "$ENV_FILE" | tail -n1 | cut -d= -f2- | tr -d '\r')"
fi
PVE_ROOT_PASSWORD="${PVE_ROOT_PASSWORD:-123}"

orb start >/dev/null

mkdir -p "$DEV_DIR/ISOs" "$DEV_DIR/VM-Backup"

docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" down -t 0 --remove-orphans --volumes || true
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" pull
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" up -d

echo "[dev-up] Waiting for container pve-1..."
for _ in $(seq 1 60); do
  if docker ps --format '{{.Names}}' | grep -qx 'pve-1'; then
    break
  fi
  sleep 1
done

if ! docker ps --format '{{.Names}}' | grep -qx 'pve-1'; then
  echo "[dev-up] ERROR: container pve-1 not running" >&2
  docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" logs --no-color | tail -n 200 >&2
  exit 1
fi

echo "[dev-up] Ensuring root password + SSH password login are enabled..."
docker exec pve-1 bash -lc "
set -euo pipefail

PASS='${PVE_ROOT_PASSWORD}'
echo \"root:\$PASS\" | chpasswd

CFG=/etc/ssh/sshd_config

ensure_kv() {
  local key=\"\$1\" val=\"\$2\"
  if grep -Eq \"^[#[:space:]]*\$key[[:space:]]+\" \"\$CFG\"; then
    sed -i -E \"s|^[#[:space:]]*\$key[[:space:]]+.*|\$key \$val|\" \"\$CFG\"
  else
    echo \"\$key \$val\" >> \"\$CFG\"
  fi
}

ensure_kv PasswordAuthentication yes
ensure_kv PermitRootLogin yes
ensure_kv UsePAM yes

(systemctl restart ssh || systemctl restart sshd || service ssh restart || true) >/dev/null 2>&1
"

echo "[dev-up] Waiting for SSH port 2222..."
for _ in $(seq 1 180); do
  if nc -z 127.0.0.1 2222 >/dev/null 2>&1; then
    echo "[dev-up] OK: SSH port is open"
    break
  fi
  sleep 1
done

if ! nc -z 127.0.0.1 2222 >/dev/null 2>&1; then
  echo "[dev-up] ERROR: SSH port never opened on 2222" >&2
  docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" logs --no-color | tail -n 200 >&2
  exit 1
fi

echo "[dev-up] Waiting for UI on https://localhost:8006 ..."
for _ in $(seq 1 180); do
  if curl -kfsS https://127.0.0.1:8006 >/dev/null 2>&1; then
    echo "[dev-up] OK: UI is up"
    echo "[dev-up] UI:   https://localhost:8006"
    echo "[dev-up] SSH:  ssh -p 2222 root@127.0.0.1"
    echo "[dev-up] PASS: $PVE_ROOT_PASSWORD"
    exit 0
  fi
  sleep 1
done

echo "[dev-up] ERROR: UI not reachable on 8006" >&2
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" logs --no-color | tail -n 200 >&2
exit 1
