#!/usr/bin/env bash
set -euo pipefail

log() { printf "\033[1;34m[INFO]\033[0m %s\n" "$*"; }
ok() { printf "\033[1;32m[ OK ]\033[0m %s\n" "$*"; }
skip() { printf "\033[1;33m[SKIP]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;31m[WARN]\033[0m %s\n" "$*"; }

LINUX_USER="terraform"
PVE_USER="terraform@pam"
PVE_GROUP="terraform-users"
PVE_ROLE="TerraformUser"
PVE_TOKEN_NAME="token"

if [[ -z "${PUBKEY_B64:-}" ]]; then
  warn "PUBKEY_B64 env var is required"
  exit 2
fi

PUBKEY="$(printf '%s' "$PUBKEY_B64" | base64 -d)"

log "Starting Proxmox bootstrap (idempotent)"

# 1) Linux user for SSH
if id "$LINUX_USER" >/dev/null 2>&1; then
  skip "Linux user '$LINUX_USER' exists"
else
  log "Creating Linux user '$LINUX_USER'"
  adduser --home "/home/$LINUX_USER" --shell /bin/bash --disabled-password --gecos "" "$LINUX_USER"
  ok "Created Linux user '$LINUX_USER'"
fi

# Ensure sudo group membership
if id -nG "$LINUX_USER" | tr ' ' '\n' | grep -qx sudo; then
  skip "User '$LINUX_USER' already in sudo group"
else
  log "Adding '$LINUX_USER' to sudo group"
  usermod -aG sudo "$LINUX_USER"
  ok "Added '$LINUX_USER' to sudo group"
fi

# Ensure SSH authorized key
SSH_DIR="/home/$LINUX_USER/.ssh"
AUTH_KEYS="$SSH_DIR/authorized_keys"

if [[ -d "$SSH_DIR" ]]; then
  skip "SSH dir exists: $SSH_DIR"
else
  log "Creating SSH dir: $SSH_DIR"
  install -d -m 0700 -o "$LINUX_USER" -g "$LINUX_USER" "$SSH_DIR"
  ok "Created SSH dir"
fi

touch "$AUTH_KEYS"
chown "$LINUX_USER:$LINUX_USER" "$AUTH_KEYS"
chmod 0600 "$AUTH_KEYS"

if grep -qF "$PUBKEY" "$AUTH_KEYS"; then
  skip "SSH pubkey already present in $AUTH_KEYS"
else
  log "Adding SSH pubkey to $AUTH_KEYS"
  echo "$PUBKEY" >>"$AUTH_KEYS"
  ok "Added SSH pubkey"
fi

# 2) Sudoers rules (tight + idempotent + validated)
SUDOERS_FILE="/etc/sudoers.d/terraform"
DESIRED="$(
  cat /dev/stdin <<'SUDO'
terraform ALL=(root) NOPASSWD: /sbin/pvesm
terraform ALL=(root) NOPASSWD: /sbin/qm
terraform ALL=(root) NOPASSWD: /usr/bin/tee /var/lib/vz/snippets/*
terraform ALL=(root) NOPASSWD: /usr/bin/tee /var/lib/vz/template/iso/*
SUDO
)"

if [[ -f "$SUDOERS_FILE" ]] && cmp -s <(printf "%s" "$DESIRED") "$SUDOERS_FILE"; then
  skip "Sudoers file already matches: $SUDOERS_FILE"
else
  log "Writing sudoers file: $SUDOERS_FILE"
  printf "%s" "$DESIRED" >"$SUDOERS_FILE"
  chmod 0440 "$SUDOERS_FILE"
  ok "Updated sudoers file"
fi

if visudo -cf "$SUDOERS_FILE" >/dev/null; then
  ok "Validated sudoers: $SUDOERS_FILE"
else
  warn "visudo validation failed: $SUDOERS_FILE"
  exit 1
fi

# 3) Snippets dir
if [[ -d /var/lib/vz/snippets ]]; then
  skip "Snippets dir exists: /var/lib/vz/snippets"
else
  log "Creating snippets dir: /var/lib/vz/snippets"
  mkdir -p /var/lib/vz/snippets
  ok "Created snippets dir"
fi

# 4) Proxmox RBAC
if pveum role list | awk '{print $1}' | grep -qx "$PVE_ROLE"; then
  skip "Proxmox role exists: $PVE_ROLE"
else
  log "Creating Proxmox role: $PVE_ROLE"
  pveum role add "$PVE_ROLE" -privs "Datastore.Allocate Datastore.AllocateSpace Datastore.AllocateTemplate Datastore.Audit Pool.Allocate Sys.Audit Sys.Console Sys.Modify SDN.Use VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.Cloudinit VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Migrate VM.Monitor VM.PowerMgmt User.Modify"
  ok "Created Proxmox role: $PVE_ROLE"
fi

if pveum group list | awk '{print $1}' | grep -qx "$PVE_GROUP"; then
  skip "Proxmox group exists: $PVE_GROUP"
else
  log "Creating Proxmox group: $PVE_GROUP"
  pveum group add "$PVE_GROUP"
  ok "Created Proxmox group: $PVE_GROUP"
fi

ACL_PRESENT="$(pveum acl list | awk -v g="$PVE_GROUP" -v r="$PVE_ROLE" '$1=="/" && $3==g && $4==r {print "yes"}' | head -n1 || true)"
if [[ "$ACL_PRESENT" == "yes" ]]; then
  skip "ACL already set: / -> group $PVE_GROUP role $PVE_ROLE"
else
  log "Setting ACL: / -> group $PVE_GROUP role $PVE_ROLE"
  pveum acl modify / -group "$PVE_GROUP" -role "$PVE_ROLE"
  ok "Set ACL"
fi

if pveum user list | awk '{print $1}' | grep -qx "$PVE_USER"; then
  skip "Proxmox user exists: $PVE_USER"
else
  log "Creating Proxmox user: $PVE_USER"
  pveum useradd "$PVE_USER" -groups "$PVE_GROUP"
  ok "Created Proxmox user: $PVE_USER"
fi

USER_GROUPS="$(pveum user list | awk -v u="$PVE_USER" '$1==u {print $5}' || true)"
if echo "$USER_GROUPS" | tr ',' '\n' | grep -qx "$PVE_GROUP"; then
  skip "User $PVE_USER already in group $PVE_GROUP"
else
  log "Ensuring user $PVE_USER is in group $PVE_GROUP"
  pveum user modify "$PVE_USER" -groups "$PVE_GROUP"
  ok "Updated user groups"
fi

# 5) Token creation (idempotent-ish)
# If token exists, skip (because you can't recover its secret anyway).
if [[ "${CREATE_TOKEN:-}" == "--create-token" ]]; then
  if pveum user token list "$PVE_USER" 2>/dev/null | awk '{print $1}' | grep -qx "$PVE_TOKEN_NAME"; then
    skip "Token already exists: $PVE_USER!$PVE_TOKEN_NAME (not recreating; secret cannot be re-shown)"
    log "If you want to rotate it, delete it in Proxmox UI/CLI and rerun with --create-token."
  else
    log "Creating token: $PVE_USER!$PVE_TOKEN_NAME (secret will be printed ONCE)"
    pveum user token add "$PVE_USER" "$PVE_TOKEN_NAME" -privsep 0
    ok "Token created (copy the value now)"
  fi
else
  skip "Token creation skipped (pass --create-token)"
fi

ok "Bootstrap complete"
