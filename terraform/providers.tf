terraform {
  required_providers {
    incus = {
      source  = "lxc/incus"
      version = "1.0.2"
    }
  }
}

provider "incus" {
  generate_client_certificates = true
  accept_remote_certificate    = true
  default_remote               = "tower"

  remote {
    name     = "tower"
    address  = "https://10.10.10.111:8443"
    protocol = "incus"
  }
}
