# Proxmox Dev Environment (macOS)

Disposable Proxmox VE instance in a container for testing Ansible/Terraform workflows locally.

## Requirements

- macOS (Apple Silicon / M1+)
- OrbStack
- Docker (via OrbStack)
- `just`

Install:

```bash
brew install orbstack just
orb start
```

## Files

- `compose.yml` — single-node Proxmox container definition
- `up.sh` — start from scratch and ensure root/password works for UI + SSH (defaults to 1Password `PVE Root`)
- `down.sh` — teardown (removes container + volumes)
- Repo `justfile` — convenience targets (`dev-up`, `dev-down`, etc.)

## Quick Start

From repo root:

```bash
just dev-up
```

UI:

- [https://localhost:8006](https://localhost:8006)
- user: `root`
- password: `PVE Root` from 1Password (default)

SSH:

```bash
ssh -p 2222 root@127.0.0.1
# password: PVE Root from 1Password (default)
```

Tear down:

```bash
just dev-down
```

## Password Override

Set a different password for a run:

```bash
PVE_ROOT_PASSWORD='your-password' just dev-up
```

By default, `dev-up` will try to read `PVE Root` from 1Password (Homelab vault). You can override the vault or item:

```bash
OP_VAULT='Homelab' OP_PVE_ROOT_ITEM='PVE Root' just dev-up
```

## Useful Commands

Container status:

```bash
just dev-ps
```

Tail logs:

```bash
just dev-logs
```

## Notes

- This runs **privileged** and uses `/dev/kvm`. Treat it as a dev-only sandbox.
- Volumes:
  - `./ISOs` → `/var/lib/vz/template/iso`
  - `./VM-Backup` → `/var/lib/vz/dump`
