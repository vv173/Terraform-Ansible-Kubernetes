terraform {
  required_providers {
    hyperv = {
      source = "taliesins/hyperv"
      version = "1.0.3"
    }
  }
}

variable "name" {
  type = string
}

variable "switch_name" {
  type = string
  default = "Default Switch"
}

variable "servers" {
  type = number
  default = 1
}

variable "username" {
  type = string
  default = ""
}

variable "password" {
  type = string
  default = ""
}




variable "integration_services" {
  type = map
  default = {
    "Guest Service Interface" = false
    "Heartbeat"               = true
    "Key-Value Pair Exchange" = true
    "Shutdown"                = true
    "Time Synchronization"    = true
    "VSS"                     = true
  }
}

resource "hyperv_vhd" "ubuntu_machine_vhd" {
  count = var.servers
  path = "C:\\Users\\Public\\Documents\\Hyper-V\\VHD\\${var.name}${count.index}.vhdx"     
  source = "C:\\Users\\Public\\Documents\\Hyper-V\\VMBackup\\Ubuntu_Server\\Virtual Hard Disks\\Ubuntu_Server.vhdx"
}

resource "hyperv_machine_instance" "ubuntu" {
  count = var.servers
  name = "${var.name}_${count.index}"
  integration_services = var.integration_services
  generation = 1
  automatic_critical_error_action = "Pause"
  automatic_critical_error_action_timeout = 30
  automatic_start_action = "StartIfRunning"
  automatic_start_delay = 0
  automatic_stop_action = "Save"
  checkpoint_type = "Production"
  dynamic_memory = true
  processor_count = 2
  state = "Running"
  memory_startup_bytes = 2147483648 # 2GB

  network_adaptors{
    name = "External Switch"
    switch_name = "External"
    dynamic_ip_address_limit = 10
    management_os = false
  }

  hard_disk_drives {
    controller_type = "Ide"
    controller_number = "0"
    controller_location = "0"
    path = hyperv_vhd.ubuntu_machine_vhd[count.index].path 
    resource_pool_name = "Primordial"
  }
  
  depends_on = [
    hyperv_vhd.ubuntu_machine_vhd
  ]

  provisioner "local-exec" {

    command = "sed -i '/\\(${var.name}\\|${var.name}_${count.index + 1}\\)/s/=.*/${self.network_adaptors[0].ip_addresses[0]}/g' ../playbooks/hosts"

  }
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = var.username
      password = var.password
      host     = self.network_adaptors[0].ip_addresses[0]
    }

    inline = [
      "sudo hostnamectl set-hostname ${var.name}_${count.index}",     
      "sudo sed -i '/127.0.1.1 terraform/c\\127.0.1.1 ${var.name}_${count.index}' /etc/hosts",   
      "sudo apt install network-manager -y",
      "sudo systemctl restart NetworkManager",
    ]
  }

}

