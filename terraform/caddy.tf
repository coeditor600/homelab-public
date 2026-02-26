resource "proxmox_virtual_environment_container" "caddy" {
  node_name = "nuc"
  vm_id     = 105

  unprivileged = true
  start_on_boot = true

  initialization {
    hostname = "caddy"

    ip_config {
      ipv4 {
        address = "10.10.30.5/24"
        gateway = "10.10.30.1"
      }
    }

    dns {
      servers = ["10.10.30.1"]
    }
  }
  
  network_interface {
    name    = "eth0"
    bridge  = "vmbr0" # Verify this is your bridge name in PVE
    vlan_id = 30
    firewall = true
  }
  memory {
    dedicated = 512
    swap = 512
  }

  device_passthrough {
    path = "/dev/net/tun"
  }

  disk {
    size = 24
    datastore_id = "local-lvm"
  }

  operating_system {
    template_file_id = "local:vztmpl/debian-13-standard_13.1-2_amd64.tar.zst"
    type             = "debian"
  }

  lifecycle {
    ignore_changes = [
      operating_system[0].template_file_id,
      unprivileged,
    ]
  }
}