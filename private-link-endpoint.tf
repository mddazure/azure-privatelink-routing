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
## Create Virtual Network - privatelink-endpoint-source
#######################################################################
resource "azurerm_virtual_network" "privatelink-endpoint-source-vnet" {
  name                = "privatelink-endpoint-source-vnet"
  location            = var.location-privatelink-endpoint
  resource_group_name = azurerm_resource_group.privatelink-endpoint-rg.name
  address_space       = ["192.168.0.0/24"]

 tags = {
    environment = "pl-endpoint-source"
    deployment  = "terraform"
    microhack    = "privatelink-routing"
  }
}
#######################################################################
## Create Route Table - udr-ple-via-fw
#######################################################################
resource "azurerm_route_table" "udr-ple-via-fw" {
  name                          = "udr-ple-via-fw"
  location            = var.location-privatelink-endpoint
  resource_group_name = azurerm_resource_group.privatelink-endpoint-rg.name
  disable_bgp_route_propagation = false

  route {
    name           = "route1"
    address_prefix = "192.168.0.132/32"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.privatelink-firewall-1.ip_configuration[0].private_ip_address
  }

    route {
    name           = "route2"
    address_prefix = "192.168.0.133/32"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.privatelink-firewall-1.ip_configuration[0].private_ip_address
  }
    route {
    name           = "route3"
    address_prefix = "192.168.100.132/32"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.privatelink-firewall-2.ip_configuration[0].private_ip_address
  }

    route {
    name           = "route4"
    address_prefix = "192.168.100.133/32"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.privatelink-firewall-2.ip_configuration[0].private_ip_address
  }
      route {
    name           = "route5"
    address_prefix = "192.168.200.132/32"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.privatelink-firewall-2.ip_configuration[0].private_ip_address
  }

    route {
    name           = "route6"
    address_prefix = "192.168.200.133/32"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.privatelink-firewall-2.ip_configuration[0].private_ip_address
  }
 tags = {
    environment = "pl-endpoint-source"
    deployment  = "terraform"
    microhack    = "privatelink-routing"
  }
}
#######################################################################
## Create Subnets - privatelink-endpoint-source
#######################################################################
resource "azurerm_subnet" "vm-subnet" {
  name                 = "vmSubnet"
  resource_group_name = azurerm_resource_group.privatelink-endpoint-rg.name
  virtual_network_name = azurerm_virtual_network.privatelink-endpoint-source-vnet.name
  address_prefixes       = ["192.168.0.0/25"]
  
}
resource "azurerm_subnet_route_table_association" "vm-subnet-via-fw" {
  subnet_id      = azurerm_subnet.vm-subnet.id
  route_table_id = azurerm_route_table.udr-ple-via-fw.id
}
resource "azurerm_subnet" "ple-bastion-subnet" {
  name                 = "AzureBastionSubnet"
 resource_group_name = azurerm_resource_group.privatelink-endpoint-rg.name
  virtual_network_name = azurerm_virtual_network.privatelink-endpoint-source-vnet.name
  address_prefixes       = ["192.168.0.160/27"]
}
resource "azurerm_subnet" "privatelink-endpoint-source-subnet" {
  name                 = "privatelink-endpoint-source-subnet"
 resource_group_name = azurerm_resource_group.privatelink-endpoint-rg.name
  virtual_network_name = azurerm_virtual_network.privatelink-endpoint-source-vnet.name
  address_prefixes       = ["192.168.0.128/27"]
  enforce_private_link_endpoint_network_policies = true
}
resource "azurerm_subnet" "fw-1-ple-subnet" {
  name                 = "AzureFirewallSubnet"
 resource_group_name = azurerm_resource_group.privatelink-endpoint-rg.name
  virtual_network_name = azurerm_virtual_network.privatelink-endpoint-source-vnet.name
  address_prefixes       = ["192.168.0.192/26"]
  enforce_private_link_endpoint_network_policies = true
}
#######################################################################
## Create Virtual Network - privatelink-endpoint-fw-vnet
#######################################################################
resource "azurerm_virtual_network" "privatelink-endpoint-fw-vnet" {
  name                = "privatelink-endpoint-fw-vnet"
  location            = var.location-privatelink-endpoint
  resource_group_name = azurerm_resource_group.privatelink-endpoint-rg.name
  address_space       = ["192.168.100.0/24"]

 tags = {
    environment = "pl-endpoint-fw"
    deployment  = "terraform"
    microhack    = "privatelink-routing"
  }
}
#######################################################################
## Create Subnets - privatelink-endpoint-fw-vnet
#######################################################################
resource "azurerm_subnet" "ple-fw-subnet" {
  name                 = "privatelink-endpoint-fw-subnet"
 resource_group_name = azurerm_resource_group.privatelink-endpoint-rg.name
  virtual_network_name = azurerm_virtual_network.privatelink-endpoint-fw-vnet.name
  address_prefixes       = ["192.168.100.128/27"]
  enforce_private_link_endpoint_network_policies = true
}
resource "azurerm_subnet" "fw-2-ple-subnet" {
  name                 = "AzureFirewallSubnet"
 resource_group_name = azurerm_resource_group.privatelink-endpoint-rg.name
  virtual_network_name = azurerm_virtual_network.privatelink-endpoint-fw-vnet.name
  address_prefixes       = ["192.168.100.192/26"]
  enforce_private_link_endpoint_network_policies = true
}
#######################################################################
## Create Virtual Network - privatelink-endpoint-only-vnet
#######################################################################
resource "azurerm_virtual_network" "privatelink-endpoint-only-vnet" {
  name                = "privatelink-endpoint-only-vnet"
  location            = var.location-privatelink-endpoint
  resource_group_name = azurerm_resource_group.privatelink-endpoint-rg.name
  address_space       = ["192.168.200.0/24"]

 tags = {
    environment = "pl-endpoint-only"
    deployment  = "terraform"
    microhack    = "privatelink-routing"
  }
}
#######################################################################
## Create Subnets - privatelink-endpoint-only-vnet
#######################################################################
resource "azurerm_subnet" "ple-fw-only-subnet" {
  name                 = "privatelink-endpoint-only-subnet"
 resource_group_name = azurerm_resource_group.privatelink-endpoint-rg.name
  virtual_network_name = azurerm_virtual_network.privatelink-endpoint-only-vnet.name
  address_prefixes       = ["192.168.200.128/27"]
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

  source_image_id = "/subscriptions/0245be41-c89b-4b46-a3cc-a705c90cd1e8/resourceGroups/image-gallery-rg/providers/Microsoft.Compute/galleries/mddimagegallery/images/windows2019-networktools/versions/2.0.0"

  #source_image_reference {
  #  offer     = "WindowsServer"
  #  publisher = "MicrosoftWindowsServer"
  #  sku       = "2019-Datacenter"
  #  version   = "latest"
  #}

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
## Create Network Interface - client-2-nic
#######################################################################
resource "azurerm_network_interface" "client-2-nic" {
  name                 = "client-2-nic"
  location             = var.location-privatelink-endpoint
  resource_group_name  = azurerm_resource_group.privatelink-endpoint-rg.name
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "client-2-ipconfig"
    subnet_id                     = azurerm_subnet.privatelink-endpoint-source-subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    environment = "pl-endpoint"
    deployment  = "terraform"
    microhack   = "privatelink-routing"
  }
}
#######################################################################
## Create Virtual Machine client-2-vm
#######################################################################
resource "azurerm_windows_virtual_machine" "client-2-vm" {
  name                  = "client-2-vm"
  location              = var.location-privatelink-endpoint
  resource_group_name   = azurerm_resource_group.privatelink-endpoint-rg.name
  network_interface_ids = [azurerm_network_interface.client-2-nic.id]
  size               = var.vmsize
  computer_name  = "client-2-vm"
  admin_username = var.username
  admin_password = var.password
  provision_vm_agent = true

  source_image_id = "/subscriptions/0245be41-c89b-4b46-a3cc-a705c90cd1e8/resourceGroups/image-gallery-rg/providers/Microsoft.Compute/galleries/mddimagegallery/images/windows2019-networktools/versions/2.0.0"

  #source_image_reference {
  #  offer     = "WindowsServer"
  #  publisher = "MicrosoftWindowsServer"
  #  sku       = "2019-Datacenter"
  #  version   = "latest"
  #}

  os_disk {
    name              = "client-2-osdisk"
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
  subnet_id             = azurerm_subnet.privatelink-endpoint-source-subnet.id
  private_service_connection {
    name                           = "ple-1-privateserviceconnection"
    private_connection_resource_id = azurerm_private_link_service.plsrv-1.id
    is_manual_connection           = false
  }
}
#######################################################################
## Create Privatelink Endpoint ple-2
#######################################################################
resource "azurerm_private_endpoint" "ple-2"{
  name                  = "ple-2"
  location              = var.location-privatelink-endpoint
  resource_group_name   = azurerm_resource_group.privatelink-endpoint-rg.name
  subnet_id             = azurerm_subnet.privatelink-endpoint-source-subnet.id
  private_service_connection {
    name                           = "ple-2-privateserviceconnection"
    private_connection_resource_id = azurerm_storage_account.privatelink-blob-mdd.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
}
#######################################################################
## Create Privatelink Endpoint ple-3
#######################################################################
resource "azurerm_private_endpoint" "ple-3"{
  name                  = "ple-3"
  location              = var.location-privatelink-endpoint
  resource_group_name   = azurerm_resource_group.privatelink-endpoint-rg.name
  subnet_id             = azurerm_subnet.ple-fw-subnet.id
  private_service_connection {
    name                           = "ple-3-privateserviceconnection"
    private_connection_resource_id = azurerm_private_link_service.plsrv-1.id
    is_manual_connection           = false
  }
}
#######################################################################
## Create Privatelink Endpoint ple-4
#######################################################################
resource "azurerm_private_endpoint" "ple-4"{
  name                  = "ple-4"
  location              = var.location-privatelink-endpoint
  resource_group_name   = azurerm_resource_group.privatelink-endpoint-rg.name
  subnet_id             = azurerm_subnet.ple-fw-subnet.id
  private_service_connection {
    name                           = "ple-4-privateserviceconnection"
    private_connection_resource_id = azurerm_storage_account.privatelink-blob-mdd.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
}
#######################################################################
## Create Privatelink Endpoint ple-5
#######################################################################
resource "azurerm_private_endpoint" "ple-5"{
  name                  = "ple-5"
  location              = var.location-privatelink-endpoint
  resource_group_name   = azurerm_resource_group.privatelink-endpoint-rg.name
  subnet_id             = azurerm_subnet.ple-fw-only-subnet.id
  private_service_connection {
    name                           = "ple-5-privateserviceconnection"
    private_connection_resource_id = azurerm_private_link_service.plsrv-1.id
    is_manual_connection           = false
  }
}
#######################################################################
## Create Privatelink Endpoint ple-6
#######################################################################
resource "azurerm_private_endpoint" "ple-6"{
  name                  = "ple-6"
  location              = var.location-privatelink-endpoint
  resource_group_name   = azurerm_resource_group.privatelink-endpoint-rg.name
  subnet_id             = azurerm_subnet.ple-fw-only-subnet.id
  private_service_connection {
    name                           = "ple-6-privateserviceconnection"
    private_connection_resource_id = azurerm_storage_account.privatelink-blob-mdd.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
}
#######################################################################
## Peer source-vnet fw-vnet
#######################################################################
resource "azurerm_virtual_network_peering" "source-fw-peer" {
  name                      = "source-fw-peer"
  resource_group_name   = azurerm_resource_group.privatelink-endpoint-rg.name
  virtual_network_name      = azurerm_virtual_network.privatelink-endpoint-source-vnet.name
  remote_virtual_network_id = azurerm_virtual_network.privatelink-endpoint-fw-vnet.id
  allow_forwarded_traffic = true
}

resource "azurerm_virtual_network_peering" "fw-source-peer" {
  name                      = "fw-source-peer"
  resource_group_name   = azurerm_resource_group.privatelink-endpoint-rg.name
  virtual_network_name      = azurerm_virtual_network.privatelink-endpoint-fw-vnet.name
  remote_virtual_network_id = azurerm_virtual_network.privatelink-endpoint-source-vnet.id
  allow_forwarded_traffic = true
}
#######################################################################
## Peer fw-vnet ple-only-vnet
#######################################################################
resource "azurerm_virtual_network_peering" "only-fw-peer" {
  name                      = "only-fw-peer"
  resource_group_name   = azurerm_resource_group.privatelink-endpoint-rg.name
  virtual_network_name      = azurerm_virtual_network.privatelink-endpoint-only-vnet.name
  remote_virtual_network_id = azurerm_virtual_network.privatelink-endpoint-fw-vnet.id
  allow_forwarded_traffic = true
}
resource "azurerm_virtual_network_peering" "fw-only-peer" {
  name                      = "fw-only-peer"
  resource_group_name   = azurerm_resource_group.privatelink-endpoint-rg.name
  virtual_network_name      = azurerm_virtual_network.privatelink-endpoint-fw-vnet.name
  remote_virtual_network_id = azurerm_virtual_network.privatelink-endpoint-only-vnet.id
  allow_forwarded_traffic = true
}