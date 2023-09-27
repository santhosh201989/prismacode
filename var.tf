variable "hub-rg" {
  type = string
  default = "rg-si-hub-net-01"
  description = "name of Hub Resource group"
}

variable "spoke1-rg" {
    type = string
    default = "rg-ci-spoke1-net-01"
    description = "name of Spoke1 RG"
}

variable "spoke2-rg" {
    type = string
    default = "rg-sea-spoke2-net-01"
    description = "name of Spoke2 RG"
}

variable "hub-location" {
  type = string
  default = "South India"
}

variable "spoke-1-location" {
    type = string
    default = "Central India"
}

variable "spoke-2-location" {
    type = string
    default = "Southeast Asia"
}

variable "hub-mgmt-nsg" {
    type = string
    default = "nsg-si-hub-snet-mgmt-01"
    description = "name of mgmt tier hub nsg"
}

variable "spoke1-webnsg-name" {
    type = string
    default = "nsg-si-spoke1-snet-web-01"
    description = "name of web tier spoke1 nsg"
}

variable "spoke2-webnsg-name" {
    type = string
    default = "nsg-sea-spoke2-snet-web-01"
    description = "name of web tier spoke2 nsg"
}

variable "spoke1-appnsg-name" {
    type = string
    default = "nsg-si-spoke1-snet-app-01"
    description = "name of app tier spoke1 nsg"
}

variable "spoke2-appnsg-name" {
    type = string
    default = "nsg-sea-spoke2-snet-app-01"
    description = "name of app tier spoke2 nsg"
}

variable "hub-untrust-nsg" {
    type = string
    default = "nsg-si-hub-snet-untrust-01"
    description = "name of untrust tier hub nsg"
}

variable "hub-trust-nsg" {
    type = string
    default = "nsg-si-hub-snet-trust-01"
    description = "name of trust tier hub nsg"
}

variable "hub-vnet" {
    type = string
    default = "vnet-si-hub-01"
    description = "name of Hub vnet"
}

variable "spoke1-vnet" {
    type = string
    default = "vnet-si-spoke1-01"
    description = "name of Spoke1 vnet"
}

variable "spoke2-vnet" {
    type = string
    default = "vnet-sea-spoke2-01"
    description = "name of Spoke2 vnet"
}

variable "mgmt-snet" {
    type = string
    default = "192.168.0.0/27"
}

variable "gateway-snet" {
    type = string
    default = "192.168.0.128/27"
}

variable "tag-value" {
    type = string
    default = "hub-vnet"
}

variable "untrust-nic-name-01" {
    type = string
    default = "nic-si-vnet1-snet-untrust-01"
}

variable "nic-spoke1-app-01" {
    type = string
    default = "nic-ci-spoke1-snet-app-01"
}

variable "nic-spoke2-app-01" {
    type = string
    default = "nic-sea-spoke2-snet-app-01"
}

variable "spoke1-web-nic-01" {
    type = string
    default = "nic-ci-spoke1-snet-web-01"
}

variable "spoke2-web-nic-01" {
    type = string
    default = "nic-sea-spoke2-snet-web-01"
}

variable "untrust-vm-name-01" {
    type= string
    default = "vm-si-hub-untrust-srv-01"
}

variable "vm-spoke1-web-01" {
    type= string
    default = "vm-ci-spoke1-web-srv-01"
}

variable "vm-spoke2-web-01" {
    type= string
    default = "vm-sea-spoke2-web-srv-01"
}

variable "trust-nic-name-01" {
    type = string
    default = "nic-si-vnet1-snet-trust-01"
}

variable "trust-vm-name-01" {
    type= string
    default = "vm-si-hub-trust-srv-01"
}

variable "spoke1-app-vm-name-01" {
    type= string
    default = "vm-ci-spoke1-app-srv-01"
}

variable "spoke2-app-vm-name-01" {
    type= string
    default = "vm-sea-spoke2-app-srv-01"
}

