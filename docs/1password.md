# 1Password Integration (Homelab)

This repo uses 1Password as the source of truth for Proxmox API endpoints and tokens, plus the bootstrap SSH key. The Proxmox bootstrap playbook reads from 1Password and writes new tokens into 1Password on first run.

## Purpose

1Password provides a single source of truth for secrets used by the Proxmox bootstrap and downstream automation. This document focuses only on the 1Password data model and how the integration is wired.

## Vault layout (Homelab)

Required items (Homelab vault):

- `proxmox/ssh-bootstrap-key` (SSH keypair)
  - `public key`
  - `private key`

- `proxmox/<host>/api` (per-host Proxmox API details)
  - `endpoint` (example: `https://192.168.1.10:8006/`)
  - `token` (example: `terraform@pam!token=...`)

## Integration points

- Service account token is read from the item:
  - `Service Account Auth Token: Homelab Service` (field `credential`)
- The bootstrap playbook reads:
  - `proxmox/ssh-bootstrap-key` → `public key`
- The bootstrap playbook writes:
  - `proxmox/<host>/api` → `endpoint`, `token`

For operational workflows (bootstrap, add node, rotation), see `proxmox/README.md`.
