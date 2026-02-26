variable "proxmox_api_token" {
  description = "The api token for proxmox"
  type        = string
  sensitive   = true
}
variable "proxmox_url" {
  description = "The proxmox URL"
  type        = string
  sensitive   = true
}

variable "ssh_key_home" {
  description = "The public SSH key to use for the containers"
  type        = string
  sensitive   = true
}
variable "ssh_key_laptop" {
  description = "The public SSH key to use for the containers"
  type        = string
  sensitive   = true
}

variable "proxmox_password" {
  description = "The password for proxmox"
  type        = string
  sensitive   = true
}

variable "talos_master_ip" {
  description = "The IP address of the Talos master node"
  type        = string
}
