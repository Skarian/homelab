## Proxmox Ansible

Bootstrap and configure Proxmox nodes for Terraform/IaC. The current playbook sets up:

- A `terraform` Linux user and SSH key
- Sudoers rules for Proxmox tooling and snippet/ISO placement
- Proxmox RBAC (role, group, user, ACL)
- API token creation and save to 1Password

### Structure

- `ansible.cfg` — Ansible defaults for this folder
- `inventories/` — inventory files per environment
- `inventories/host_vars/` — per-host secrets (gitignored)
- `playbooks/` — Proxmox playbooks

### Secrets and per-host passwords

By default, the bootstrap playbook reads the root password from the 1Password
item `PVE Root`. The only required per-host value is the endpoint.

Example (normal case):

```yaml
pve_endpoint: "https://<host-or-ip>:8006/"
```

Optional override (only if a host has a different root password):

```yaml
ansible_password: "your-host-password"
pve_endpoint: "https://<host-or-ip>:8006/"
```

### 1Password integration

All 1Password access is centralized in the Ansible role `roles/op_secrets`.
The playbook reads the SSH public key from 1Password and writes per-host API tokens to 1Password.

Requirements:

- 1Password CLI (`op`)
- 1Password item `Service Account Auth Token: Homelab Service` with a `credential` field
- 1Password item `proxmox/ssh-bootstrap-key` with a `public key` field
- 1Password item `PVE Root` with a `password` field

Per-host API items are stored as: `proxmox/<host>/api` with fields `endpoint` and `token`.

For 1Password data model details, see `docs/1password.md`.

### Roles

- `roles/op_secrets` — reads 1Password items and syncs per-host API tokens/endpoints.

### Bootstrap from scratch (dev or real node)

1. Create/confirm the SSH key item in 1Password:
   - `proxmox/ssh-bootstrap-key`
2. Create/confirm the service account token item:
   - `Service Account Auth Token: Homelab Service` (field: `credential`)
3. Add a host entry in the inventory:
   - `inventories/dev.yml` or `inventories/homelab.yml`
4. Add per-host secrets (gitignored):
   - `inventories/host_vars/<host>.yml`
   - Example (override only):
     ```yaml
     ansible_password: "<root-password>"
     pve_endpoint: "https://<host-or-ip>:8006/"
     ```
5. Run the bootstrap:
   ```bash
   ansible-playbook -i inventories/dev.yml playbooks/bootstrap-proxmox.yml
   ```
6. Verify in 1Password that `proxmox/<host>/api` exists and contains:
   - `endpoint`
   - `token`

### Add a new node (checklist)

1. Add host to inventory (`dev.yml` or `homelab.yml`).
2. Create `inventories/host_vars/<host>.yml` with:
   - `ansible_password`
   - `pve_endpoint`
3. Ensure the 1Password app is unlocked.
4. Run the bootstrap playbook.
5. Confirm `proxmox/<host>/api` is populated in 1Password.

### Token rotation

Proxmox tokens can only be revealed at creation time. If the token already exists, the playbook cannot re-read its secret.

To rotate:

1. Delete the old token in Proxmox.
2. Re-run the playbook to generate a new token and store it in 1Password.

### Troubleshooting

- **1Password read fails**
  - Ensure the 1Password app is unlocked.
  - Ensure the service account item exists and has a `credential` field.

- **Token already exists**
  - This is expected on subsequent runs. Delete/rotate if needed.

- **Missing endpoint**
  - Make sure `pve_endpoint` exists in `inventories/host_vars/<host>.yml` for first bootstrap.

- **Missing root password**
  - Ensure `PVE Root` exists in 1Password with a `password` field.
  - Or set `ansible_password` in `inventories/host_vars/<host>.yml` as an override.

### Example run

From `proxmox/`:

```bash
ansible-playbook -i inventories/dev.yml playbooks/bootstrap-proxmox.yml
```
