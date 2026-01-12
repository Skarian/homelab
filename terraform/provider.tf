variable "pve_endpoint" {
  type        = string
  description = "e.g. https://pve.example.com:8006/"
}

variable "pve_api_token" {
  type        = string
  sensitive   = true
  description = "e.g. root@pam!terraform=00000000-0000-0000-0000-000000000000"
}

provider "proxmox" {
  endpoint  = var.pve_endpoint
  api_token = var.pve_api_token

  insecure = true
}
