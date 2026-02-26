resource "proxmox_virtual_environment_container" "nfs_storage" {
  node_name = "nuc"
  vm_id     = 111

  unprivileged  = false
  start_on_boot = true

  initialization {
    hostname = "nfs-storage"

    ip_config {
      ipv4 {
        address = "10.10.30.110/24"
        gateway = "10.10.30.1"
      }
    }
    ip_config {
      ipv4 {
        address = "10.99.99.100/24"
      }
    }

    dns {
      servers = ["10.10.30.1"]
    }

    user_account {
      keys = [var.ssh_key_home, var.ssh_key_laptop]
    }
  }

  network_interface {
    name     = "eth0"
    bridge   = "vmbr0"
    vlan_id  = 30
    firewall = true
  }

  network_interface {
    name   = "eth1"
    bridge = "vmbr1"
  }

  memory {
    dedicated = 512
    swap      = 512
  }

  cpu {
    cores = 1
  }

  disk {
    size         = 24
    datastore_id = "local-lvm"
  }
  features {
    nesting = true
    #mount   = ["nfs", "cifs"]
  }

  mount_point {
    volume = "/mnt/external_drive"
    path   = "/export/data"
  }

  operating_system {
    template_file_id = "local:vztmpl/debian-13-standard_13.1-2_amd64.tar.zst"
    type             = "debian"
  }
}
