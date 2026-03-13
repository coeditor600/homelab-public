resource "incus_server" "tower" {
  remote = "tower"
}

# Network for servarr services
resource "incus_network" "arr_internal" {
  remote = "tower"
  name   = "arr-internal"
  type   = "bridge"

  config = {
    "ipv4.address" = "172.40.0.1/24"
    "ipv4.nat"     = "false" # Disables internet routing out of this bridge
    "ipv6.address" = "none"
  }
}


resource "incus_storage_volume" "nzbget_config" {
  remote = "tower"
  pool   = "local"
  name   = "nzbget-config"
}

resource "incus_storage_volume" "prowlarr_config" {
  remote = "tower"
  pool   = "local"
  name   = "prowlarr-config"
}

resource "incus_storage_volume" "sonarr_config" {
  remote = "tower"
  pool   = "local"
  name   = "sonarr-config"
}

resource "incus_storage_volume" "radarr_config" {
  remote = "tower"
  pool   = "local"
  name   = "radarr-config"
}

resource "incus_storage_volume" "profilarr_config" {
  remote = "tower"
  pool   = "local"
  name   = "profilarr-config"
}

resource "incus_storage_volume" "seerr_config" {
  remote = "tower"
  pool   = "local"
  name   = "seerr-config"
}

resource "incus_storage_volume" "jellyfin_config" {
  remote = "tower"
  pool   = "local"
  name   = "jellyfin-config"
}

resource "incus_storage_volume" "caddy_config" {
  remote = "tower"
  pool   = "local"
  name   = "caddy-config"
}

resource "incus_storage_volume" "caddy_data" {
  remote = "tower"
  pool   = "local"
  name   = "caddy-data"
}

resource "incus_storage_volume" "shared_downloads" {
  remote = "tower"
  pool   = "local"
  name   = "shared-downloads"
}

# 2. The Updated Base Profile (Dual NIC Setup)
resource "incus_profile" "arr_base" {
  remote = "tower"
  name   = "arr-base"

  config = {
    "environment.PUID" = var.PUID
    "environment.PGID" = var.PGID
    "environment.TZ"   = var.TZ
    "boot.autostart"   = "true"
    "security.nesting" = "true"
    "raw.lxc"          = "lxc.mount.entry = tmpfs run tmpfs rw,nodev,relatime,mode=755,create=dir 0 0"
  }

  # External access via your router's VLAN 30
  device {
    name = "eth0"
    type = "nic"
    properties = {
      nictype = "macvlan"
      parent  = "enp9s0" # IMPORTANT: Change this to your tower's actual physical NIC name (e.g., eth0, enp4s0)
      vlan    = "30"
    }
  }

  #  Internal access via the Incus bridge
  device {
    name = "eth1"
    type = "nic"
    properties = {
      network = incus_network.arr_internal.name
    }
  }
}

# NZBGet container
resource "incus_instance" "nzbget" {
  remote   = "tower"
  name     = "nzbget"
  image    = "lscr:linuxserver/nzbget:latest"
  profiles = ["default", incus_profile.arr_base.name]

  config = {
    "user.network-config" = <<-EOT
      version: 2
      ethernets:
        eth0:
          addresses:
            - 10.10.30.162/24
          nameservers:
            addresses: [10.10.30.1, 8.8.4.4]
          routes:
            - to: 0.0.0.0/0
              via: 10.10.30.1  # Your physical VLAN 30 Gateway
    EOT
  }

  device {
    name = "eth1"
    type = "nic"
    properties = {
      network        = incus_network.arr_internal.name
      "ipv4.address" = "172.40.0.2"
    }
  }

  device {
    name = "config"
    type = "disk"
    properties = {
      source = incus_storage_volume.nzbget_config.name
      path   = "/config"
      pool   = "local"
    }
  }

  device {
    name = "data"
    type = "disk"
    properties = {
      source = incus_storage_volume.shared_downloads.name
      path   = "/downloads"
      pool   = "local"
    }
  }

  device {
    name = "jellyfin"
    type = "disk"
    properties = {
      source = "/datapool/media"
      path   = "/jellyfin"
      shift  = "true"
    }
  }

  depends_on = [incus_storage_volume.nzbget_config, incus_storage_volume.shared_downloads]
}

# Prowlarr container
resource "incus_instance" "prowlarr" {
  remote   = "tower"
  name     = "prowlarr"
  image    = "lscr:linuxserver/prowlarr:latest"
  profiles = ["default", incus_profile.arr_base.name]

  config = {
    "user.network-config" = <<-EOT
      version: 2
      ethernets:
        eth0:
          addresses:
            - 10.10.30.163/24
          nameservers:
            addresses: [10.10.30.1, 8.8.4.4]
          routes:
            - to: 0.0.0.0/0
              via: 10.10.30.1  # Your physical VLAN 30 Gateway
    EOT
  }

  device {
    name = "eth1"
    type = "nic"
    properties = {
      network        = incus_network.arr_internal.name
      "ipv4.address" = "172.40.0.3"
    }
  }

  device {
    name = "config"
    type = "disk"
    properties = {
      source = incus_storage_volume.prowlarr_config.name
      path   = "/config"
      pool   = "local"
    }
  }

  depends_on = [incus_storage_volume.prowlarr_config, incus_storage_volume.shared_downloads]
}

# Sonarr container
resource "incus_instance" "sonarr" {
  remote   = "tower"
  name     = "sonarr"
  image    = "lscr:linuxserver/sonarr:latest"
  profiles = ["default", incus_profile.arr_base.name]

  config = {
    "user.network-config" = <<-EOT
      version: 2
      ethernets:
        eth0:
          addresses:
            - 10.10.30.164/24
          nameservers:
            addresses: [10.10.30.1, 8.8.4.4]
          routes:
            - to: 0.0.0.0/0
              via: 10.10.30.1  # Your physical VLAN 30 Gateway
    EOT
  }

  device {
    name = "eth1"
    type = "nic"
    properties = {
      network        = incus_network.arr_internal.name
      "ipv4.address" = "172.40.0.4"
    }
  }

  device {
    name = "config"
    type = "disk"
    properties = {
      source = incus_storage_volume.sonarr_config.name
      path   = "/config"
      pool   = "local"
    }
  }

  device {
    name = "data"
    type = "disk"
    properties = {
      source = incus_storage_volume.shared_downloads.name
      path   = "/downloads"
      pool   = "local"
    }
  }

  device {
    name = "jellyfin"
    type = "disk"
    properties = {
      source = "/datapool/media"
      path   = "/jellyfin"
      shift  = "true"
    }
  }

  depends_on = [incus_storage_volume.sonarr_config, incus_storage_volume.shared_downloads]
}

# Radarr container
resource "incus_instance" "radarr" {
  remote   = "tower"
  name     = "radarr"
  image    = "lscr:linuxserver/radarr:latest"
  profiles = ["default", incus_profile.arr_base.name]

  config = {
    "user.network-config" = <<-EOT
      version: 2
      ethernets:
        eth0:
          addresses:
            - 10.10.30.165/24
          nameservers:
            addresses: [10.10.30.1, 8.8.4.4]
          routes:
            - to: 0.0.0.0/0
              via: 10.10.30.1  # Your physical VLAN 30 Gateway
    EOT
  }

  device {
    name = "eth1"
    type = "nic"
    properties = {
      network        = incus_network.arr_internal.name
      "ipv4.address" = "172.40.0.5"
    }
  }

  device {
    name = "config"
    type = "disk"
    properties = {
      source = incus_storage_volume.radarr_config.name
      path   = "/config"
      pool   = "local"
    }
  }

  device {
    name = "data"
    type = "disk"
    properties = {
      source = incus_storage_volume.shared_downloads.name
      path   = "/downloads"
      pool   = "local"
    }
  }

  device {
    name = "jellyfin"
    type = "disk"
    properties = {
      source = "/datapool/media"
      path   = "/jellyfin"
      shift  = "true"
    }
  }
  depends_on = [incus_storage_volume.radarr_config, incus_storage_volume.shared_downloads]
}

# Profilarr container
resource "incus_instance" "profilarr" {
  remote   = "tower"
  name     = "profilarr"
  image    = "docker:santiagosayshey/profilarr:latest"
  profiles = ["default", incus_profile.arr_base.name]

  device {
    name = "eth1"
    type = "nic"
    properties = {
      network        = incus_network.arr_internal.name
      "ipv4.address" = "172.40.0.6"
    }
  }

  device {
    name = "config"
    type = "disk"
    properties = {
      source = incus_storage_volume.profilarr_config.name
      path   = "/config"
      pool   = "local"
    }
  }

  depends_on = [incus_storage_volume.profilarr_config, incus_storage_volume.shared_downloads]
}

# Jellyseerr container
resource "incus_instance" "seerr" {
  remote   = "tower"
  name     = "seerr"
  image    = "images:debian/12/cloud" #
  profiles = ["default"]

  config = {
    "boot.autostart"   = "true"
    "security.nesting" = "true"

    # Static IPs via Cloud-Init
    "cloud-init.network-config" = <<-EOT
      version: 2
      ethernets:
        eth0:
          dhcp4: no
          addresses: [10.10.30.169/24]
          routes:
            - to: 0.0.0.0/0
              via: 10.10.30.1
          nameservers:
            addresses: [10.10.30.1, 8.8.4.4]
        eth1:
          dhcp4: no
          addresses: [172.40.0.9/24]
    EOT

    # Automatic Installation
    "cloud-init.user-data" = <<-EOT
      #cloud-config
      packages:
        - curl
        - gnupg
        - git
      runcmd:
        - curl -sL https://deb.nodesource.com/setup_22.x | bash -
        - apt-get install -y nodejs
        - npm install -g pnpm@latest-10
        - mkdir -p /opt/seerr
        - cd /opt/seerr
        - git clone https://github.com/seerr-team/seerr.git .
        - git checkout main
        - CYPRESS_INSTALL_BINARY=0 pnpm install --frozen-lockfile
        - pnpm build
        # Create a systemd service to keep it running
        - |
          cat <<EOF > /etc/systemd/system/jellyseerr.service
          [Unit]
          Description=Jellyseerr Service
          After=network.target
          [Service]
          Type=simple
          User=root
          WorkingDirectory=/opt/seerr
          ExecStart=pnpm start
          Restart=always
          Environment=NODE_ENV=production
          Environment=PORT=5055
          Environment=CONFIG_DIRECTORY=/app/config
          [Install]
          WantedBy=multi-user.target
          EOF
        - systemctl enable --now jellyseerr
    EOT
  }

  # External access via your router's VLAN 30
  device {
    name = "eth0"
    type = "nic"
    properties = {
      nictype = "macvlan"
      parent  = "enp9s0" # IMPORTANT: Change this to your tower's actual physical NIC name (e.g., eth0, enp4s0)
      vlan    = "30"
    }
  }

  #  Internal access via the Incus bridge
  device {
    name = "eth1"
    type = "nic"
    properties = {
      network        = incus_network.arr_internal.name
      "ipv4.address" = "172.40.0.9"
    }
  }

  device {
    name = "config"
    type = "disk"
    properties = {
      source = incus_storage_volume.seerr_config.name
      path   = "/app/config"
      pool   = "local"
    }
  }
  depends_on = [incus_storage_volume.seerr_config, incus_storage_volume.shared_downloads]
}

# Jellyfin container
resource "incus_instance" "jellyfin" {
  remote   = "tower"
  name     = "jellyfin"
  image    = "lscr:linuxserver/jellyfin:latest"
  profiles = ["default", incus_profile.arr_base.name]

  config = {
    "nvidia.runtime"             = true
    "nvidia.driver.capabilities" = "compute,video,utility"
    "nvidia.require.cuda"        = ">=12.0" # Match your host's CUDA version
    "user.network-config"        = <<-EOT
      version: 2
      ethernets:
        eth0:
          addresses:
            - 10.10.30.168/24
          nameservers:
            addresses: [10.10.30.1, 8.8.4.4]
          routes:
            - to: 0.0.0.0/0
              via: 10.10.30.1  # Your physical VLAN 30 Gateway
    EOT
  }

  device {
    name = "eth1"
    type = "nic"
    properties = {
      network        = incus_network.arr_internal.name
      "ipv4.address" = "172.40.0.8"
    }
  }


  device {
    name = "config"
    type = "disk"
    properties = {
      source = incus_storage_volume.jellyfin_config.name
      path   = "/config"
      pool   = "local"
    }
  }
  device {
    name = "mygpu"
    type = "gpu"
    properties = {
      # An empty block satisfies Terraform's schema
      # Alternatively, you can explicitly set it: "gputype" = "physical"
    }
  }

  device {
    name = "jellyfin"
    type = "disk"
    properties = {
      source = "/datapool/media"
      path   = "/jellyfin"
      shift  = "true"
    }
  }

  depends_on = [incus_storage_volume.jellyfin_config, incus_storage_volume.shared_downloads]
}


resource "incus_instance" "caddy" {
  remote   = "tower"
  name     = "caddy"
  image    = "images:debian/12/cloud"
  profiles = ["default", incus_profile.arr_base.name]

  config = {
    "boot.autostart" = "true"

    # 1. Network Configuration (The "How it talks")
    "cloud-init.network-config" = <<-EOT
      version: 2
      ethernets:
        eth0:
          dhcp4: false
          dhcp6: false
          addresses:
            - 10.10.30.170/24
          routes:
            - to: 0.0.0.0/0
              via: 10.10.30.1
          nameservers:
            addresses: [10.10.30.1, 8.8.8.4]
        eth1:
          dhcp4: false
          dhcp6: false
          addresses:
            - 172.40.0.10/24
    EOT

    # 2. Automation (The "What it does")
    "cloud-init.user-data" = <<-EOT
      #cloud-config
      package_update: true
      package_upgrade: true
      packages:
        - debian-keyring
        - debian-archive-keyring
        - apt-transport-https
        - curl
      runcmd:
        - [ sh, -c, "curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg" ]
        - [ sh, -c, "curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list" ]
        - apt-get update
        - apt-get install -y caddy
        - systemctl enable caddy
        - systemctl start caddy
    EOT
  }

  device {
    name = "eth1"
    type = "nic"
    properties = {
      network        = incus_network.arr_internal.name
      "ipv4.address" = "172.40.0.10"
    }
  }


  device {
    name = "config"
    type = "disk"
    properties = {
      pool   = "local"
      source = incus_storage_volume.caddy_config.name
      path   = "/etc/caddy"
    }
  }

  device {
    name = "data"
    type = "disk"
    properties = {
      pool   = "local"
      source = incus_storage_volume.caddy_data.name
      path   = "/data"
    }
  }
}
