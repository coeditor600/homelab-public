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
  image    = "ghcr:seerr-team/seerr"
  profiles = ["default", incus_profile.arr_base.name]

  config = {
    "security.nesting" = "true"
    "raw.lxc"          = <<-EOT
      lxc.mount.entry = tmpfs run tmpfs rw,nodev,relatime,mode=755,create=dir 0 0
      lxc.mount.entry = tmpfs tmp tmpfs rw,nodev,relatime,mode=755,create=dir 0 0
    EOT
  }

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


#resource "incus_instance" "caddy" {
#remote   = "tower"
#name     = "caddy"
#image    = "docker:caddy:latest"
#profiles = ["default", incus_profile.arr_base.name]

#config = {
#  "security.nesting" = "true"
#  "raw.lxc"          = <<-EOT
#    lxc.mount.entry = tmpfs run tmpfs rw,nodev,relatime,mode=755,#create=dir 0 0
#    lxc.mount.entry = tmpfs tmp tmpfs rw,nodev,relatime,mode=755,#create=dir 0 0
#  EOT
#}

#device {
#  name = "eth1"
#  type = "nic"
#  properties = {
#    network        = incus_network.arr_internal.name
#    "ipv4.address" = "172.40.0.10"
#  }
#}

#device {
#  name = "eth0"
#  type = "nic"
#  properties = {
#    nictype = "macvlan"
#    parent  = "enp9s0" # IMPORTANT: Change this to your tower's actual #physical NIC name (e.g., eth0, enp4s0)
#    vlan    = "30"
#    #hwaddr = "10:66:6a:83:e4:85"
#  }
#}

#device {
#  name = "config"
#  type = "disk"
#  properties = {
#    pool   = "local"
#    source = incus_storage_volume.caddy_config.name
#    path   = "/etc/caddy"
#  }
#}

#device {
#name = "data"
#type = "disk"
#properties = {
#  pool   = "local"
#  source = incus_storage_volume.caddy_data.name
#   path   = "/data"
#  }
# }
#}
