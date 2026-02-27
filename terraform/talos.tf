resource "talos_machine_secrets" "this" {
  talos_version = "v1.12.4"
}

data "talos_machine_configuration" "control_plane" {
  cluster_name     = "k3s-master"
  cluster_endpoint = "https://${var.talos_master_ip}:6443"
  machine_type     = "controlplane"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  talos_version    = "v1.12.4"

  config_patches = [
    yamlencode({
      machine = {
        install = {
          disk       = "/dev/sda"
          image      = "factory.talos.dev/metal-installer/d7fce3e7d0d5cb3ac7d0af45c38fbaa82931d6270f1f236d626366e0d66ae79c:v1.12.4"
          bootloader = true
          wipe       = true
        }
        network = {
          nameservers = ["10.10.30.1"]
          interfaces = [
            {
              interface = "eth0"
              addresses = ["${var.talos_master_ip}/24"]
              dhcp      = false
              routes = [
                {
                  network = "0.0.0.0/0"
                  gateway = "10.10.30.1"
                }
              ]
            },
            {
              interface = "eth1"
              dhcp      = false
              addresses = ["10.99.99.200/24"]
            }
          ]
        }
      }
      cluster = {
        allowSchedulingOnControlPlanes = true
      }
    })
  ]
}

resource "proxmox_virtual_environment_file" "talos_config" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "nuc"

  source_raw {
    data      = data.talos_machine_configuration.control_plane.machine_configuration
    file_name = "user-data"
  }

  lifecycle {
    ignore_changes = [source_raw]
  }
}

resource "proxmox_virtual_environment_file" "talos_metadata" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "nuc"

  source_raw {
    data = yamlencode({
      instance-id = "k3s-master"
      hostname    = "k3s-master"
    })
    file_name = "meta-data"
  }

  lifecycle {
    ignore_changes = [source_raw]
  }
}

resource "proxmox_virtual_environment_file" "talos_iso" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "nuc"

  source_file {
    path      = "https://factory.talos.dev/image/e5136c7057101c31544df2a7e042e584e6a48ad0e85130bf285c53c2d706626e/v1.12.4/metal-amd64.iso"
    file_name = "talos-v1.12.4-proxmox.iso"
  }

  #lifecycle {
  # ignore_changes = [source_file]
  #}
}

resource "proxmox_virtual_environment_vm" "k3s_master" {
  node_name = "nuc"
  vm_id     = 200
  name      = "k3s-master"

  machine       = "q35"
  scsi_hardware = "virtio-scsi-single"
  bios          = "ovmf"

  cpu {
    cores = 2
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 8192
    floating  = 2048
  }

  agent {
    enabled = true
  }

  network_device {
    bridge   = "vmbr0"
    vlan_id  = 30
    model    = "virtio"
    firewall = false
  }

  network_device {
    bridge   = "vmbr1"
    model    = "virtio"
    firewall = false
  }

  efi_disk {
    datastore_id = "local-lvm"
    file_format  = "raw"
    type         = "4m"
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    iothread     = true
    discard      = "on"
    size         = 32
  }

  initialization {
    datastore_id      = "local-lvm"
    user_data_file_id = "local:snippets/user-data"
    meta_data_file_id = "local:snippets/meta-data"
    interface         = "ide2"
  }

  operating_system {
    type = "l26"
  }

  cdrom {
    file_id   = "local:iso/talos-v1.12.4-proxmox.iso"
    interface = "ide3"
  }

  smbios {
    serial = "ds=nocloud;s=;h=k3s-master"
  }

  boot_order = ["ide3", "scsi0"]

  lifecycle {
    ignore_changes = [initialization, cdrom, boot_order]
  }

  depends_on = [proxmox_virtual_environment_file.talos_iso]
}

resource "talos_machine_configuration_apply" "this" {
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.control_plane.machine_configuration
  node                        = var.talos_master_ip
  endpoint                    = var.talos_master_ip
  depends_on                  = [proxmox_virtual_environment_vm.k3s_master]
}

#resource "talos_machine_bootstrap" "this" {
#  depends_on           = [talos_machine_configuration_apply.this]
#  client_configuration = talos_machine_secrets.this.client_configuration
#  node                 = var.talos_master_ip
#  endpoint             = var.talos_master_ip#
#}

resource "talos_cluster_kubeconfig" "this" {
  #depends_on           = [talos_machine_bootstrap.this]
  depends_on           = [talos_machine_configuration_apply.this]
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = var.talos_master_ip
}

data "talos_client_configuration" "this" {
  cluster_name         = "k3s-master"
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = [var.talos_master_ip]
  nodes                = [var.talos_master_ip]
}

resource "local_file" "talosconfig" {
  content  = data.talos_client_configuration.this.talos_config
  filename = "${path.module}/talosconfig"
}

resource "local_file" "kubeconfig" {
  content  = talos_cluster_kubeconfig.this.kubeconfig_raw
  filename = "${path.module}/kubeconfig"
}
