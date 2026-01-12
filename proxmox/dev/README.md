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
- `up.sh` — start from scratch and ensure root/password works for UI + SSH
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
- password: `123` (default)

SSH:

```bash
ssh -p 2222 root@127.0.0.1
# password: 123
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
