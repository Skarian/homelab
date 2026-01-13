## Proxmox Ansible

Bootstrap and configure Proxmox nodes for Terraform/IaC. The current playbook sets up:
- A `terraform` Linux user and SSH key
- Sudoers rules for Proxmox tooling and snippet/ISO placement
- Proxmox RBAC (role, group, user, ACL)
- API token creation and local save

### Structure
- `ansible.cfg` — Ansible defaults for this folder
- `inventories/` — inventory files per environment
- `inventories/host_vars/` — per-host secrets (gitignored)
- `playbooks/` — Proxmox playbooks
- `.secrets/` — local output for generated API tokens (gitignored)

### Secrets and per-host passwords
Store SSH passwords in `inventories/host_vars/<hostname>.yml` so Ansible picks the right password
based on the target host. These files are gitignored.

Example:
```yaml
ansible_password: "your-host-password"
```

### Example run
From `proxmox/`:
```bash
ANSIBLE_CONFIG=./ansible.cfg ansible-playbook -i inventories/dev.yml playbooks/bootstrap-proxmox.yml
```

### Quick start for a new Proxmox node
1) Add the host to the right inventory file in `inventories/`.
2) Create `inventories/host_vars/<hostname>.yml` with `ansible_password`.
3) Run the bootstrap playbook (see example above).
4) Use the generated token from `.secrets/` for Terraform or API access.
