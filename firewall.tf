#######################################################################
## Create Resource Group
#######################################################################

resource "azurerm_resource_group" "privatelink-firewall-rg" {
  name     = "privatelink-firewall-rg"
  location = var.location-privatelink-firewall
 tags = {
    environment = "pl-firewall"
    deployment  = "terraform"
    microhack   = "privatelink-routing"
  }
}
#######################################################################
## Create Virtual Network - privatelink-firewall
#######################################################################
resource "azurerm_virtual_network" "privatelink-firewall-vnet" {
  name                = "privatelink-firewall-vnet"
  location            = var.location-privatelink-firewall
  resource_group_name = azurerm_resource_group.privatelink-firewall-rg.name
  address_space       = ["192.168.100.0/24"]

 tags = {
    environment = "pl-firewall"
    deployment  = "terraform"
    microhack    = "privatelink-routing"
  }
}
#######################################################################
## Create Subnets - firewall
#######################################################################
resource "azurerm_subnet" "fw-subnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name = azurerm_resource_group.privatelink-firewall-rg.name
  virtual_network_name = azurerm_virtual_network.privatelink-firewall-vnet.name
  address_prefixes       = ["192.168.100.0/26"]
}
resource "azurerm_subnet" "fw-mgmt-subnet" {
  name                 = "AzureFirewallManagementSubnet"
 resource_group_name = azurerm_resource_group.privatelink-firewall-rg.name
  virtual_network_name = azurerm_virtual_network.privatelink-firewall-vnet.name
  address_prefixes       = ["192.168.100.64/26"]
}
#######################################################################
## Create Firewall
#######################################################################
resource "azurerm_public_ip" "fw-pubip" {
  name                = "fw-pubip"
  location              = var.location-privatelink-firewall
  resource_group_name   = azurerm_resource_group.privatelink-firewall-rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}
resource "azurerm_firewall" "privatelink-firewall" {
  name                = "privatelink-firewall"
 location            = var.location-privatelink-firewall
  resource_group_name = azurerm_resource_group.privatelink-firewall-rg.name

  ip_configuration {
    name                 = "fw_in_fw-vnet"
    subnet_id            = azurerm_subnet.fw-subnet.id
    public_ip_address_id = azurerm_public_ip.fw-pubip.id
  }
   tags = {
    environment = "pl-firewall"
    deployment  = "terraform"
    microhack    = "privatelink-routing"
  }
}
#  ip_configuration {
#    name                 = "fw_in_ple-vnet"
#    subnet_id            = azurerm_subnet.fw-ple-subnet.id
#    public_ip_address_id = azurerm_public_ip.fw-pubip.id
# }

resource "azurerm_firewall_network_rule_collection" "netw-rule-coll-1" {
  name                = "netw-rule-coll-1"
  azure_firewall_name = azurerm_firewall.privatelink-firewall.name
  resource_group_name = azurerm_resource_group.privatelink-firewall-rg.name
  priority            = 100
  action              = "Allow"

  rule {
    name = "ple-allow"

    source_addresses = [
      "192.168.0.0/25",
    ]

    destination_ports = [
      "*",
    ]

    destination_addresses = [
      "192.168.0.128/27",
    ]

    protocols = [
      "TCP",
      "UDP",
    ]
  }
}

