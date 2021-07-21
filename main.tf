terraform {
  required_providers {
    hyperv = {
      source = "taliesins/hyperv"
      version = "1.0.3"
    }
  }
}

variable "username" {
  type = string
  default = ""
}

variable "password" {
  type = string
  default = ""
}

variable "host" {
  type = string
  default = ""
}

variable "ubuntu_username" {
  type = string
  default = ""
}

variable "ubuntu_password" {
  type = string
  default = ""
}

variable "ubuntu_host" {
  type = string
  default = ""
}

variable "switch_name" {
  type = string
  default = "Default Switch"
}


provider "hyperv" {
  user            = "${var.username}"
  password        = "${var.password}"
  host            = "${var.host}"
  port            = 5986
  https           = true
  insecure        = true
  timeout         = "30s"
}

module "masters" {
    source = "./modules/linux/"
    name = "kubernetes-master"
    password = var.ubuntu_password
    username = var.ubuntu_username
    switch_name = var.switch_name
}


module "nodes" {
    source = "./modules/linux/"
    name = "kubernetes-worker"
    servers = 2
    password = var.ubuntu_password
    username = var.ubuntu_username
    switch_name = var.switch_name
}


# resource "null_resource" "Gitlab-Runner_Ubuntu" {
#   provisioner "local-exec" {

#     command = "ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook ./ansible/gitlab_runner-linux.yml -i ./ansible/inventory.ini"

#   }

#   depends_on = [
#     module.masters
#   ]
# }