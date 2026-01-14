# Work Log

## 2026-01-12 — Proxmox Ansible Bootstrap

- Implemented idempotent Proxmox bootstrap playbook using JSON output parsing for roles, groups, users, ACLs, and tokens.
- Improved raw bootstrap steps to check/install python3 and sudo only when missing.
- Parameterized sudoers user to match `terraform_linux_user`.
- Updated token handling to avoid re-creation and write local secrets only on creation.
- Moved Proxmox inventory vars to `proxmox/inventories/group_vars/` and added per-host secrets in `proxmox/inventories/host_vars/`.
- Set token output directory to `proxmox/.secrets/` and ensured gitignore coverage.
- Added `proxmox/README.md` documenting structure, secrets, example run, and quick start.
- Moved root `justfile` into `proxmox/` and updated paths for dev helpers.

### Notes
- Deprecation warning originates from `ansible.posix` `authorized_key` importing `to_native` via deprecated path; upstream update required to remove.

### Observations
- Project direction is IaC + automation for a homelab; dev environment uses a disposable Proxmox container for local testing.
- Overall lab architecture is still evolving; no complete topology documented yet.
- Prefer `pveum` JSON output for idempotent checks to avoid fragile table parsing.
- Secrets live in gitignored per-host files under `proxmox/inventories/host_vars/`, and generated tokens go to `proxmox/.secrets/`.

## 2026-01-14 — 1Password Integration, Bootstrap Hardening, and Docs

- Implemented 1Password-backed bootstrap flow: service account token, SSH pubkey, and per-host API token/endpoint stored in 1Password.
- Removed reliance on local `.secrets/` for tokens; made endpoint writes idempotent and marked sensitive steps `no_log`.
- Added PVE Root password sourcing from 1Password with optional host_vars override.
- Updated dev startup to prefer 1Password PVE Root and removed password echo.
- Added `docs/1password.md` and reorganized documentation between `docs/` and `proxmox/README.md` for clear workflows.
- Verified bootstrap idempotency on fresh dev environment (second run changed=0).
