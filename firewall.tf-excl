
#######################################################################
## Create Firewall-1
#######################################################################
resource "azurerm_public_ip" "fw-1-pubip" {
  name                = "fw-1-pubip"
  location              = var.location-privatelink-endpoint
  resource_group_name   = azurerm_resource_group.privatelink-endpoint-rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}
resource "azurerm_firewall" "privatelink-firewall-1" {
  name                = "privatelink-firewall-1"
  location            = var.location-privatelink-endpoint
  resource_group_name = azurerm_resource_group.privatelink-endpoint-rg.name

  ip_configuration {
    name                 = "fw-1-ipconfig"
    subnet_id            = azurerm_subnet.fw-1-ple-subnet.id
    public_ip_address_id = azurerm_public_ip.fw-1-pubip.id
  }
   firewall_policy_id   =  azurerm_firewall_policy.privatelink-firewall-policy.id

   tags = {
    environment = "pl-firewall-1"
    deployment  = "terraform"
    microhack    = "privatelink-routing"
  }
}
#######################################################################
## Create Firewall-2
#######################################################################
resource "azurerm_public_ip" "fw-2-pubip" {
  name                = "fw-2-pubip"
  location              = var.location-privatelink-endpoint
  resource_group_name   = azurerm_resource_group.privatelink-endpoint-rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}
resource "azurerm_firewall" "privatelink-firewall-2" {
  name                = "privatelink-firewall-2"
  location            = var.location-privatelink-endpoint
  resource_group_name = azurerm_resource_group.privatelink-endpoint-rg.name

  ip_configuration {
    name                 = "fw-2-ipconfig"
    subnet_id            = azurerm_subnet.fw-2-ple-subnet.id
    public_ip_address_id = azurerm_public_ip.fw-2-pubip.id
  }
  firewall_policy_id   =  azurerm_firewall_policy.privatelink-firewall-policy.id
   tags = {
    environment = "pl-firewall-1"
    deployment  = "terraform"
    microhack    = "privatelink-routing"
  }
}
#######################################################################
## Create Firewall Policy
#######################################################################
resource "azurerm_firewall_policy" "privatelink-firewall-policy" {
  name                = "privatelink-firewall-policy"
  location              = var.location-privatelink-endpoint
  resource_group_name   = azurerm_resource_group.privatelink-endpoint-rg.name
}

resource "azurerm_firewall_policy_rule_collection_group" "privatelink-firewall-policy-rule-group" {
  name                  = "privatelink-firewall-policy-rule-group"
  firewall_policy_id    = azurerm_firewall_policy.privatelink-firewall-policy.id
  priority            = 100
  network_rule_collection {
    name        = "netw-rule-coll-1"
    action      = "Allow"
    priority    = 500
    rule {
        name        = "ple-allow"    
        source_addresses = ["192.168.0.0/25"]
        destination_ports = ["1-64000"]
        destination_addresses = ["192.168.0.128/27","192.168.100.128/27","192.168.200.128/27"]
        protocols = ["TCP","UDP"]
    } 
    }
}

