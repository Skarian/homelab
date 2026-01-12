## Run it

```bash
chmod +x proxmox/bootstrap.sh proxmox/bootstrap.remote.sh
./proxmox/bootstrap.sh root@<PVE_IP_OR_HOST> ~/.ssh/id_ed25519.pub --create-token
```

Re-run safely anytime:

```bash
./proxmox/bootstrap.sh root@<PVE_IP_OR_HOST> ~/.ssh/id_ed25519.pub
```

---

### Next step after this: wire Terraform to use

- API token for Proxmox API
- SSH user `terraform` for snippet/image placement
