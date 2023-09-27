terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.51.0"
    }
  }
}



provider "azurerm" {
  subscription_id = "43fbf665-8e3e-444d-b3d1-bacb42346ff2"
  client_id       = "455a8a10-bbed-437b-8717-d68989d00acf"
  client_secret   = "MM~8Q~CzzVByYvIgUdv-j7ocDZq.G2~fwY7nob.r"
  tenant_id       = "f7d729a0-ce3b-4e6b-ae9e-c2151e555467"
  features {}
}

resource "azurerm_resource_group" "hubrg" {
  name = var.hub-rg
  location = var.hub-location
}



resource "azurerm_network_security_group" "hub-mgmt-nsg" {
  name                = var.hub-mgmt-nsg
  location            = var.hub-location
  resource_group_name = var.hub-rg
}

resource "azurerm_network_security_group" "hub-untrust-nsg" {
  name                = var.hub-untrust-nsg
  location            = var.hub-location
  resource_group_name = var.hub-rg
}

resource "azurerm_network_security_group" "hub-trust-nsg" {
  name                = var.hub-trust-nsg
  location            = var.hub-location
  resource_group_name = var.hub-rg

  security_rule {
    name                       = "deny-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_virtual_network" "hub-vnet" {
  name                = var.hub-vnet
  location            = var.hub-location
  resource_group_name = var.hub-rg
  address_space       = ["192.168.0.0/24"]
  dns_servers         = ["192.168.0.249", "192.168.0.250"]




  tags = {
    environment = "Production"
  }

}

  resource "azurerm_subnet" "subnet1" {
  name                 = "snet-si-hub-mgmt-01"
  resource_group_name  = azurerm_resource_group.hubrg.name
  virtual_network_name = azurerm_virtual_network.hub-vnet.name
  address_prefixes     = ["192.168.0.0/27"]
}

  resource "azurerm_subnet" "subnet2" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.hubrg.name
  virtual_network_name = azurerm_virtual_network.hub-vnet.name
  address_prefixes     = ["192.168.0.128/27"]
}

  resource "azurerm_subnet" "subnet3" {
  name                 = "snet-si-hub-untrust-01"
  resource_group_name  = azurerm_resource_group.hubrg.name
  virtual_network_name = azurerm_virtual_network.hub-vnet.name
  address_prefixes     = ["192.168.0.64/27"]
}

  resource "azurerm_subnet" "subnet4" {
  name                 = "snet-si-hub-trust-01"
  resource_group_name  = azurerm_resource_group.hubrg.name
  virtual_network_name = azurerm_virtual_network.hub-vnet.name
  address_prefixes     = ["192.168.0.96/27"]
}

resource "azurerm_subnet" "subnet5" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.hubrg.name
  virtual_network_name = azurerm_virtual_network.hub-vnet.name
  address_prefixes     = ["192.168.0.128/27"]
}

resource "azurerm_subnet" "subnet6" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.hubrg.name
  virtual_network_name = azurerm_virtual_network.hub-vnet.name
  address_prefixes     = ["192.168.0.160/27"]
}

resource "azurerm_subnet_network_security_group_association" "hub-untrust-nsg-snet-association" {
  subnet_id                 = azurerm_subnet.subnet3.id
  network_security_group_id = azurerm_network_security_group.hub-untrust-nsg.id
}

resource "azurerm_subnet_network_security_group_association" "hub-trust-nsg-snet-association" {
  subnet_id                 = azurerm_subnet.subnet4.id
  network_security_group_id = azurerm_network_security_group.hub-trust-nsg.id
}

resource "azurerm_public_ip" "bastion-pip" {
  name                = "pip-si-hub-bst-01"
  location            = azurerm_resource_group.hubrg.location
  resource_group_name = azurerm_resource_group.hubrg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion-hub" {
  name                = "bst-si-hub-01"
  location            = azurerm_resource_group.hubrg.location
  resource_group_name = azurerm_resource_group.hubrg.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.subnet6.id
    public_ip_address_id = azurerm_public_ip.bastion-pip.id
  }
}

resource "azurerm_public_ip" "azfw-pip" {
  name                = "pip-si-azfw-hub-01"
  location            = azurerm_resource_group.hubrg.location
  resource_group_name = azurerm_resource_group.hubrg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall" "hub-fw" {
  name                = "fw-si-hub-01"
  location            = azurerm_resource_group.hubrg.location
  resource_group_name = azurerm_resource_group.hubrg.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.subnet5.id
    public_ip_address_id = azurerm_public_ip.azfw-pip.id
  }
}


resource "azurerm_network_interface" "untrust-nic-01" {
  name                = var.untrust-nic-name-01
  location            = var.hub-location
  resource_group_name = var.hub-rg

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.subnet3.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "vm-untrust-01" {
  name                  = var.untrust-vm-name-01
  location              = azurerm_resource_group.hubrg.location
  resource_group_name   = azurerm_resource_group.hubrg.name
  network_interface_ids = [azurerm_network_interface.untrust-nic-01.id]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "os-disk-01"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

    os_profile {
    computer_name  = "vm-si-hub-untrust-srv-01"
    admin_username = "admin"
    admin_password = "Password1234!"
  }

    os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}


resource "azurerm_network_interface" "trust-nic-01" {
  name                = var.trust-nic-name-01
  location            = var.hub-location
  resource_group_name = var.hub-rg

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.subnet4.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "vm-trust-01" {
  name                  = var.trust-vm-name-01
  location              = azurerm_resource_group.hubrg.location
  resource_group_name   = azurerm_resource_group.hubrg.name
  network_interface_ids = [azurerm_network_interface.trust-nic-01.id]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "os-disk-01"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

    os_profile {
    computer_name  = "vm-si-hub-trust-srv-01"
    admin_username = "admin"
    admin_password = "Password1234!"
  }

    os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}

resource "azurerm_public_ip" "pip-hub-vng" {
  name                = "pip-si-hub-vng"
  location            = var.hub-location
  resource_group_name = var.hub-rg

  allocation_method = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "vng-hub-vnet" {
  name                = "vng-si-hub-vng-vpn-01"
  location            = azurerm_resource_group.hubrg.location
  resource_group_name = azurerm_resource_group.hubrg.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "VpnGw3"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.pip-hub-vng.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.subnet2.id
  }
}

resource "azurerm_storage_account" "to_monitor" {
  name                     = "storsihub01"
  resource_group_name      = azurerm_resource_group.hubrg.name
  location                 = azurerm_resource_group.hubrg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_monitor_action_group" "main" {
  name                = "triggertowebhook"
  resource_group_name = azurerm_resource_group.hubrg.name
  short_name          = "firetoapi"

  webhook_receiver {
    name        = "callmyapi"
    service_uri = "http://example.com/alert"
  }
}

resource "azurerm_monitor_metric_alert" "gateway-alert" {
  name                = "alert-si-hub-01"
  resource_group_name = azurerm_resource_group.hubrg.name
  scopes              = [azurerm_storage_account.to_monitor.id]
  description         = "Action will be triggered when Transactions count is greater than 50."

  criteria {
    metric_namespace = "Microsoft.Storage/storageAccounts"
    metric_name      = "Transactions"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 50

    dimension {
      name     = "ApiName"
      operator = "Include"
      values   = ["*"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}

resource "azurerm_resource_group" "spoke1-rg" {
  name = var.spoke1-rg
  location = var.spoke-1-location
}

resource "azurerm_network_security_group" "spoke1-web-nsg" {
  name                = var.spoke1-webnsg-name
  location            = var.spoke-1-location
  resource_group_name = var.spoke1-rg

  security_rule {
    name                       = "allow_onprem"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "172.18.0.0/24"
    destination_address_prefix = "192.168.1.0/27"
  }
}

resource "azurerm_network_security_group" "spoke1-app-nsg" {
  name                = var.spoke1-appnsg-name
  location            = var.spoke-1-location
  resource_group_name = var.spoke1-rg
}

resource "azurerm_virtual_network" "spoke1-vnet" {
  name                = var.spoke1-vnet
  location            = var.spoke-1-location
  resource_group_name = var.spoke1-rg
  address_space       = ["192.168.1.0/24"]
  dns_servers         = ["192.168.0.249", "192.168.0.250"]


  tags = {
    environment = "Production"
  }

}

  resource "azurerm_subnet" "spoke1-subnet1" {
  name                 = "snet-si-spoke1-web-01"
  resource_group_name  = azurerm_resource_group.spoke1-rg.name
  virtual_network_name = azurerm_virtual_network.spoke1-vnet.name
  address_prefixes     = ["192.168.1.0/27"]
}

  resource "azurerm_subnet" "spoke1-subnet2" {
  name                 = "snet-si-spoke1-app-01"
  resource_group_name  = azurerm_resource_group.spoke1-rg.name
  virtual_network_name = azurerm_virtual_network.spoke1-vnet.name
  address_prefixes     = ["192.168.1.32/27"]
}

  resource "azurerm_subnet" "spoke1-subnet3" {
  name                 = "snet-si-spoke1-db-01"
  resource_group_name  = azurerm_resource_group.spoke1-rg.name
  virtual_network_name = azurerm_virtual_network.spoke1-vnet.name
  address_prefixes     = ["192.168.1.64/27"]
}


resource "azurerm_subnet_network_security_group_association" "spoke1-web-nsg-snet-association" {
  subnet_id                 = azurerm_subnet.spoke1-subnet1.id
  network_security_group_id = azurerm_network_security_group.spoke1-web-nsg.id
}

resource "azurerm_subnet_network_security_group_association" "spoke1-app-nsg-snet-association" {
  subnet_id                 = azurerm_subnet.spoke1-subnet2.id
  network_security_group_id = azurerm_network_security_group.spoke1-app-nsg.id
}

resource "azurerm_network_interface" "spoke1-web-nic-01" {
  name                = var.spoke1-web-nic-01
  location            = var.spoke-1-location
  resource_group_name = var.spoke1-rg

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.spoke1-subnet1.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "vm-spoke1-web-01" {
  name                  = var.vm-spoke1-web-01
  location              = azurerm_resource_group.spoke1-rg.location
  resource_group_name   = azurerm_resource_group.spoke1-rg.name
  network_interface_ids = [azurerm_network_interface.spoke1-web-nic-01.id]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "os-disk-01"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

    os_profile {
    computer_name  = "vm-ci-spoke1-web-srv-01"
    admin_username = "admin"
    admin_password = "Password1234!"
  }

    os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}

resource "azurerm_network_interface" "spoke1-app-nic-01" {
  name                = var.nic-spoke1-app-01
  location            = var.spoke-1-location
  resource_group_name = var.spoke1-rg

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.spoke1-subnet2.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "vm-spoke1-app-01" {
  name                  = var.spoke1-app-vm-name-01
  location              = azurerm_resource_group.spoke1-rg.location
  resource_group_name   = azurerm_resource_group.spoke1-rg.name
  network_interface_ids = [azurerm_network_interface.spoke1-app-nic-01.id]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "os-disk-01"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

    os_profile {
    computer_name  = "vm-ci-spoke1-app-srv-01"
    admin_username = "admin"
    admin_password = "Password1234!"
  }

    os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}

resource "azurerm_virtual_network_peering" "hub-to-spoke1-peering" {
  name                      = "vnet-peer-hubtospoke1"
  resource_group_name       = azurerm_resource_group.hubrg.name
  virtual_network_name      = azurerm_virtual_network.hub-vnet.name
  remote_virtual_network_id = azurerm_virtual_network.spoke1-vnet.id
}

resource "azurerm_virtual_network_peering" "spoke1-to-hub-peering" {
  name                      = "vnet-peer-spoke1tohub"
  resource_group_name       = azurerm_resource_group.spoke1-rg.name
  virtual_network_name      = azurerm_virtual_network.spoke1-vnet.name
  remote_virtual_network_id = azurerm_virtual_network.hub-vnet.id
}

resource "azurerm_resource_group" "spoke2rg" {
  name = var.spoke2-rg
  location = var.spoke-2-location
}

resource "azurerm_network_security_group" "spoke2-web-nsg" {
  name                = var.spoke2-webnsg-name
  location            = var.spoke-2-location
  resource_group_name = var.spoke2-rg

  security_rule {
    name                       = "allow_onprem"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "172.18.0.0/24"
    destination_address_prefix = "192.168.1.0/27"
  }
}

resource "azurerm_network_security_group" "spoke2-app-nsg" {
  name                = var.spoke2-appnsg-name
  location            = var.spoke-2-location
  resource_group_name = var.spoke2-rg
}

resource "azurerm_virtual_network" "spoke2-vnet" {
  name                = var.spoke2-vnet
  location            = var.spoke-2-location
  resource_group_name = var.spoke2-rg
  address_space       = ["192.168.2.0/24"]
  dns_servers         = ["192.168.0.249", "192.168.0.250"]


  tags = {
    environment = "Production"
  }

}

  resource "azurerm_subnet" "spoke2-subnet1" {
  name                 = "snet-sea-spoke2-web-01"
  resource_group_name  = azurerm_resource_group.spoke2rg.name
  virtual_network_name = azurerm_virtual_network.spoke2-vnet.name
  address_prefixes     = ["192.168.2.0/27"]
}

  resource "azurerm_subnet" "spoke2-subnet2" {
  name                 = "snet-sea-spoke2-app-01"
  resource_group_name  = azurerm_resource_group.spoke2rg.name
  virtual_network_name = azurerm_virtual_network.spoke2-vnet.name
  address_prefixes     = ["192.168.2.32/27"]
}

  resource "azurerm_subnet" "spoke2-subnet3" {
  name                 = "snet-sea-spoke2-db-01"
  resource_group_name  = azurerm_resource_group.spoke2rg.name
  virtual_network_name = azurerm_virtual_network.spoke2-vnet.name
  address_prefixes     = ["192.168.2.64/27"]
}

  resource "azurerm_subnet" "spoke2-subnet4" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.spoke2rg.name
  virtual_network_name = azurerm_virtual_network.spoke2-vnet.name
  address_prefixes     = ["192.168.2.96/27"]
}

resource "azurerm_subnet_network_security_group_association" "spoke2-web-nsg-snet-association" {
  subnet_id                 = azurerm_subnet.spoke2-subnet1.id
  network_security_group_id = azurerm_network_security_group.spoke2-web-nsg.id
}

resource "azurerm_subnet_network_security_group_association" "spoke2-app-nsg-snet-association" {
  subnet_id                 = azurerm_subnet.spoke2-subnet2.id
  network_security_group_id = azurerm_network_security_group.spoke2-app-nsg.id
}

resource "azurerm_network_interface" "spoke2-web-nic-01" {
  name                = var.spoke2-web-nic-01
  location            = var.spoke-2-location
  resource_group_name = var.spoke2-rg

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.spoke2-subnet1.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "vm-spoke2-web-01" {
  name                  = var.vm-spoke2-web-01
  location              = azurerm_resource_group.spoke2rg.location
  resource_group_name   = azurerm_resource_group.spoke2rg.name
  network_interface_ids = [azurerm_network_interface.spoke2-web-nic-01.id]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "os-disk-01"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

    os_profile {
    computer_name  = "vm-sea-spoke2-web-srv-01"
    admin_username = "admin"
    admin_password = "Password1234!"
  }

    os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}

resource "azurerm_network_interface" "spoke2-app-nic-01" {
  name                = var.nic-spoke2-app-01
  location            = var.spoke-2-location
  resource_group_name = var.spoke2-rg

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.spoke2-subnet2.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "vm-spoke2-app-01" {
  name                  = var.spoke2-app-vm-name-01
  location              = azurerm_resource_group.spoke2rg.location
  resource_group_name   = azurerm_resource_group.spoke2rg.name
  network_interface_ids = [azurerm_network_interface.spoke2-app-nic-01.id]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "os-disk-01"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

    os_profile {
    computer_name  = "vm-sea-spoke2-app-srv-01"
    admin_username = "admin"
    admin_password = "Password1234!"
  }

    os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}

resource "azurerm_public_ip" "pip-spoke2-vng" {
  name                = "pip-sea-vng-vpn-01"
  location            = azurerm_resource_group.spoke2rg.location
  resource_group_name = azurerm_resource_group.spoke2rg.name

  allocation_method = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "vng-spoke2-vnet" {
  name                = "vng-sea-spoke2-vng-vpn-01"
  location            = azurerm_resource_group.spoke2rg.location
  resource_group_name = azurerm_resource_group.spoke2rg.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "VpnGw3"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.pip-spoke2-vng.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.spoke2-subnet4.id
  }
}

resource "azurerm_virtual_network_gateway_connection" "hub-to-spoke2_vnet" {
  name                = "hub-to-spoke2_vnet"
  location            = azurerm_resource_group.hubrg.location
  resource_group_name = azurerm_resource_group.hubrg.name

  type                            = "Vnet2Vnet"
  virtual_network_gateway_id      = azurerm_virtual_network_gateway.vng-hub-vnet.id
  peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.vng-spoke2-vnet.id

  shared_key = "4-v3ry-53cr37-1p53c-5h4r3d-k3y"
}

resource "azurerm_virtual_network_gateway_connection" "spoke2-to-hub_vnet" {
  name                = "spoke2-to-hub_vnet"
  location            = azurerm_resource_group.spoke2rg.location
  resource_group_name = azurerm_resource_group.spoke2rg.name

  type                            = "Vnet2Vnet"
  virtual_network_gateway_id      = azurerm_virtual_network_gateway.vng-spoke2-vnet.id
  peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.vng-hub-vnet.id

  shared_key = "4-v3ry-53cr37-1p53c-5h4r3d-k3y"
}