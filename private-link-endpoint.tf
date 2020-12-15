#######################################################################
## Create Resource Group
#######################################################################

resource "azurerm_resource_group" "privatelink-endpoint-rg" {
  name     = "privatelink-endpoint-rg"
  location = var.location-privatelink-endpoint
 tags = {
    environment = "pl-endpoint"
    deployment  = "terraform"
    microhack   = "privatelink-routing"
  }
}
#######################################################################
## Create Virtual Network - privatelink-endpoint
#######################################################################
resource "azurerm_virtual_network" "privatelink-endpoint-vnet" {
  name                = "privatelink-endpoint-vnet"
  location            = var.location-privatelink-endpoint
  resource_group_name = azurerm_resource_group.privatelink-endpoint-rg.name
  address_space       = ["192.168.0.0/24"]

 tags = {
    environment = "pl-endpoint"
    deployment  = "terraform"
    microhack    = "privatelink-routing"
  }
}
#######################################################################
## Create Subnets - privatelink-endpoint
#######################################################################
resource "azurerm_subnet" "vm-subnet" {
  name                 = "vmSubnet"
  resource_group_name = azurerm_resource_group.privatelink-endpoint-rg.name
  virtual_network_name = azurerm_virtual_network.privatelink-endpoint-vnet.name
  address_prefixes       = ["192.168.0.0/25"]
}
resource "azurerm_subnet" "ple-bastion-subnet" {
  name                 = "AzureBastionSubnet"
 resource_group_name = azurerm_resource_group.privatelink-endpoint-rg.name
  virtual_network_name = azurerm_virtual_network.privatelink-endpoint-vnet.name
  address_prefixes       = ["192.168.0.160/27"]
}
resource "azurerm_subnet" "ple-subnet" {
  name                 = "privatelink-endpoint-subnet"
 resource_group_name = azurerm_resource_group.privatelink-endpoint-rg.name
  virtual_network_name = azurerm_virtual_network.privatelink-endpoint-vnet.name
  address_prefixes       = ["192.168.0.128/27"]
  enforce_private_link_endpoint_network_policies = true
}
#######################################################################
## Create Network Interface - client-1-nic
#######################################################################
resource "azurerm_network_interface" "client-1-nic" {
  name                 = "client-1-nic"
  location             = var.location-privatelink-endpoint
  resource_group_name  = azurerm_resource_group.privatelink-endpoint-rg.name
  enable_ip_forwarding = false

  ip_configuration {
    name                          = "client-1-ipconfig"
    subnet_id                     = azurerm_subnet.vm-subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    environment = "pl-endpoint"
    deployment  = "terraform"
    microhack   = "privatelink-routing"
  }
}
#######################################################################
## Create Virtual Machine client-1-vm
#######################################################################
resource "azurerm_windows_virtual_machine" "client-1-vm" {
  name                  = "client-1-vm"
  location              = var.location-privatelink-endpoint
  resource_group_name   = azurerm_resource_group.privatelink-endpoint-rg.name
  network_interface_ids = [azurerm_network_interface.client-1-nic.id]
  size               = var.vmsize
  computer_name  = "client-1-vm"
  admin_username = var.username
  admin_password = var.password
  provision_vm_agent = true

  source_image_reference {
    offer     = "WindowsServer"
    publisher = "MicrosoftWindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  os_disk {
    name              = "client-1-osdisk"
    caching           = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }
  
  tags = {
    environment = "pl-endpoint"
    deployment  = "terraform"
    microhack   = "privatelink-routing"
  }
}
#######################################################################
## Create Bastion bastion-ple
#######################################################################
resource "azurerm_public_ip" "bastion-ple-pubip" {
  name                = "bastion-ple-pubip"
  location              = var.location-privatelink-endpoint
  resource_group_name   = azurerm_resource_group.privatelink-endpoint-rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion-ple" {
  name                = "bastion-ple"
  location              = var.location-privatelink-endpoint
  resource_group_name   = azurerm_resource_group.privatelink-endpoint-rg.name

  ip_configuration {
    name                 = "bastion-ple-configuration"
    subnet_id            = azurerm_subnet.ple-bastion-subnet.id
    public_ip_address_id = azurerm_public_ip.bastion-ple-pubip.id
  }
}
#######################################################################
## Create Privatelink Endpoint ple-1
#######################################################################
resource "azurerm_private_endpoint" "ple-1"{
  name                  = "ple-1"
  location              = var.location-privatelink-endpoint
  resource_group_name   = azurerm_resource_group.privatelink-endpoint-rg.name
  subnet_id             = azurerm_subnet.ple-subnet.id
  private_service_connection {
    name                           = "ple-1-privateserviceconnection"
    private_connection_resource_id = azurerm_private_link_service.plsrv-1.id
    is_manual_connection           = false
  }

}