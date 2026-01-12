variable "node_name"       { type = string } # e.g. "pve"
variable "template_vm_id"  { type = number } # e.g. 9001
variable "vm_name"         { type = string } # e.g. "debian-test-01"
variable "vm_datastore_id" { type = string } # e.g. "local-lvm" or your ZFS pool storage ID
variable "bridge"          { type = string } # e.g. "vmbr0"

variable "ssh_public_key_path" {
  type        = string
  description = "Path to your SSH public key, e.g. ~/.ssh/id_ed25519.pub"
}

resource "proxmox_virtual_environment_vm" "debian" {
  node_name   = var.node_name
  name        = var.vm_name
  description = "Managed by Terraform"
  tags        = ["terraform", "debian"]
  started     = true
  on_boot     = true

  agent {
    enabled = true
  }

  clone {
    node_name = var.node_name
    vm_id     = var.template_vm_id
  }

  operating_system {
    type = "l26"
  }

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 2048
  }

  # Helps avoid Debian 12 cloud-image weirdness; provider explicitly calls this out.
  serial_device {
    device = "socket"
  }

  vga {
    type = "serial0"
  }

  disk {
    datastore_id = var.vm_datastore_id
    interface    = "scsi0"
    size         = 20
    discard      = "on"
  }

  network_device {
    bridge  = var.bridge
    model   = "virtio"
    enabled = true
  }

  initialization {
    datastore_id = var.vm_datastore_id

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_account {
      username = "debian"
      keys     = [trimspace(file(var.ssh_public_key_path))]
    }
  }
}

output "vm_ipv4_addresses" {
  value = proxmox_virtual_environment_vm.debian.ipv4_addresses
}
