# homelab

Homelab Infrastructure‑as‑Code repo for Proxmox + Terraform with 1Password‑backed secrets.

## At a glance

- Ansible bootstraps Proxmox, creates RBAC, and stores API tokens in 1Password.
- Terraform provisions VMs using the Proxmox API token from 1Password.
- Dev environment provides a disposable Proxmox container for local testing.

## Where to start

- `docs/1password.md` — secrets model and bootstrap flow
- `proxmox/` — Ansible bootstrap for Proxmox nodes
- `terraform/` — Terraform templates for Proxmox VMs
- `proxmox/dev/README.md` — local Proxmox dev container
