set shell := ["zsh", "-ceu"]

dev-up:
  chmod +x proxmox/dev/up.sh proxmox/dev/down.sh
  proxmox/dev/up.sh

dev-down:
  chmod +x proxmox/dev/down.sh
  proxmox/dev/down.sh

dev-ps:
  docker ps --format 'table {{{{.Names}}}}\t{{{{.Status}}}}\t{{{{.Ports}}}}' | sed -n '1p;/pve-1/p'

dev-logs:
  docker logs -f --tail=200 pve-1

dev-ssh:
  ssh -p 2222 root@127.0.0.1
