provider "azurerm" {
  version = "2.43.0"
  features {}
}
#######################################################################
## Create Resource Group
#######################################################################
resource "azurerm_resource_group" "privatelink-service-rg" {
  name     = "privatelink-service-rg"
  location = var.location-privatelink-service
 tags = {
    environment = "pl-service"
    deployment  = "terraform"
    microhack    = "privatelink-routing"
  }
}
#######################################################################
## Create Virtual Network - privatelink-service
#######################################################################
resource "azurerm_virtual_network" "privatelink-service-vnet" {
  name                = "privatelink-service-vnet"
  location            = var.location-privatelink-service
  resource_group_name = azurerm_resource_group.privatelink-service-rg.name
  address_space       = ["172.16.1.0/24"]

 tags = {
    environment = "pl-service"
    deployment  = "terraform"
    microhack    = "privatelink-routing"
  }
}
#######################################################################
## Create NAT Gatewat natGW (outbound internet from vms behind lb)
#######################################################################
resource "azurerm_public_ip" "natGW-pubip" {
  name                = "natGW-pubip"
  location            = var.location-privatelink-service
  resource_group_name = azurerm_resource_group.privatelink-service-rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}
resource "azurerm_nat_gateway" "natGW" {
  name                    = "natGW"
  location            = var.location-privatelink-service
  resource_group_name = azurerm_resource_group.privatelink-service-rg.name
  sku_name                = "Standard"
}
resource "azurerm_nat_gateway_public_ip_association" "natGW-pubip-ass"{
   nat_gateway_id       = azurerm_nat_gateway.natGW.id
   public_ip_address_id = azurerm_public_ip.natGW-pubip.id
}

#######################################################################
## Create Subnets - privatelink-service
#######################################################################
resource "azurerm_subnet" "backend-subnet" {
  name                 = "backendSubnet"
  resource_group_name = azurerm_resource_group.privatelink-service-rg.name
  virtual_network_name = azurerm_virtual_network.privatelink-service-vnet.name
  address_prefixes       = ["172.16.1.0/25"]
}
resource "azurerm_subnet_nat_gateway_association" "natGW-backendsubnet" {
  subnet_id      = azurerm_subnet.backend-subnet.id
  nat_gateway_id = azurerm_nat_gateway.natGW.id
}
resource "azurerm_subnet" "pls-bastion-subnet" {
  name                 = "AzureBastionSubnet"
 resource_group_name = azurerm_resource_group.privatelink-service-rg.name
  virtual_network_name = azurerm_virtual_network.privatelink-service-vnet.name
  address_prefixes       = ["172.16.1.128/27"]
}
resource "azurerm_subnet" "frontend-subnet" {
  name                 = "frontendSubnet"
 resource_group_name = azurerm_resource_group.privatelink-service-rg.name
  virtual_network_name = azurerm_virtual_network.privatelink-service-vnet.name
  address_prefixes       = ["172.16.1.160/28"]
}
resource "azurerm_subnet" "nat-subnet" {
  name                 = "natSubnet"
 resource_group_name = azurerm_resource_group.privatelink-service-rg.name
  virtual_network_name = azurerm_virtual_network.privatelink-service-vnet.name
  address_prefixes       = ["172.16.1.176/28"]
  enforce_private_link_service_network_policies = true
}


#######################################################################
## Create Bastion bastion-pls
#######################################################################
resource "azurerm_public_ip" "bastion-pls-pubip" {
  name                = "bastion-pls-pubip"
  location            = var.location-privatelink-service
  resource_group_name = azurerm_resource_group.privatelink-service-rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion-pls" {
  name                = "bastion-pls"
  location            = var.location-privatelink-service
  resource_group_name = azurerm_resource_group.privatelink-service-rg.name

  ip_configuration {
    name                 = "bastion-pls-configuration"
    subnet_id            = azurerm_subnet.pls-bastion-subnet.id
    public_ip_address_id = azurerm_public_ip.bastion-pls-pubip.id
  }
}
##########################################################
## Install IIS role on backend-1-vm
##########################################################
resource "azurerm_virtual_machine_extension" "install-iis-backend-1-vm" {
    
  name                 = "install-iis-backend-1-vm"
  virtual_machine_id   = azurerm_windows_virtual_machine.backend-1-vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

   settings = <<SETTINGS
    {
        "commandToExecute":"powershell -ExecutionPolicy Unrestricted Add-WindowsFeature Web-Server; powershell -ExecutionPolicy Unrestricted Add-Content -Path \"C:\\inetpub\\wwwroot\\Default.htm\" -Value $($env:computername)"
    }
SETTINGS
}
##########################################################
## Install IIS role on backend-2-vm
##########################################################
resource "azurerm_virtual_machine_extension" "install-iis-backend-2-vm" {
    
  name                 = "install-iis-backend-2-vm"
  virtual_machine_id   = azurerm_windows_virtual_machine.backend-2-vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

   settings = <<SETTINGS
    {
        "commandToExecute":"powershell -ExecutionPolicy Unrestricted Add-WindowsFeature Web-Server; powershell -ExecutionPolicy Unrestricted Add-Content -Path \"C:\\inetpub\\wwwroot\\Default.htm\" -Value $($env:computername)"
    }
SETTINGS
}
#######################################################################
## Create Virtual Machine backend-1-vm
#######################################################################
resource "azurerm_windows_virtual_machine" "backend-1-vm" {
  name                  = "backend-1-vm"
  resource_group_name   = azurerm_resource_group.privatelink-service-rg.name
  location              = var.location-privatelink-service
  network_interface_ids = [azurerm_network_interface.backend-1-nic.id]
  size               = var.vmsize
  computer_name  = "backend-1-vm"
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
    name              = "backend-1-osdisk"
    caching           = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }
  
 tags = {
    environment = "pl-service"
    deployment  = "terraform"
    microhack    = "privatelink-routing"
  }
}
#######################################################################
## Create Virtual Machine backend-2-vm
#######################################################################
resource "azurerm_windows_virtual_machine" "backend-2-vm" {
  name                  = "backend-2-vm"
  resource_group_name   = azurerm_resource_group.privatelink-service-rg.name
  location              = var.location-privatelink-service
  network_interface_ids = [azurerm_network_interface.backend-2-nic.id]
  size               = var.vmsize
  computer_name  = "backend-2-vm"
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
    name              = "backend-2-osdisk"
    caching           = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }
  
 tags = {
    environment = "pl-service"
    deployment  = "terraform"
    microhack    = "privatelink-routing"
  }
}
#######################################################################
## Create Network Interface - backend-1-nic
#######################################################################
resource "azurerm_network_interface" "backend-1-nic" {
  name                 = "backend-1-nic"
  resource_group_name   = azurerm_resource_group.privatelink-service-rg.name
  location              = var.location-privatelink-service
  enable_ip_forwarding = false

  ip_configuration {
    name                          = "backend-1-ipconfig"
    subnet_id                     = azurerm_subnet.backend-subnet.id
    private_ip_address_allocation = "Dynamic"
  }

 tags = {
    environment = "pl-service"
    deployment  = "terraform"
    microhack    = "privatelink-routing"
  }
}
#######################################################################
## Create Network Interface - backend-2-nic
#######################################################################
resource "azurerm_network_interface" "backend-2-nic" {
  name                 = "backend-2-nic"
  resource_group_name   = azurerm_resource_group.privatelink-service-rg.name
  location              = var.location-privatelink-service
  enable_ip_forwarding = false

  ip_configuration {
    name                          = "backend-2-ipconfig"
    subnet_id                     = azurerm_subnet.backend-subnet.id
    private_ip_address_allocation = "Dynamic"
  }


 tags = {
    environment = "pl-service"
    deployment  = "terraform"
    microhack    = "privatelink-routing"
  }
}
#######################################################################
## Create Load Balancer - lb-1
#######################################################################
resource "azurerm_lb" "lb-1" {
  name                = "lb-1"
  sku                 = "Standard"
    resource_group_name   = azurerm_resource_group.privatelink-service-rg.name
  location              = var.location-privatelink-service

  frontend_ip_configuration {
  
    name                 = "lb-1-frontend-ipconfig"
    private_ip_address = "172.16.1.164"
    private_ip_address_allocation = "Static"
    subnet_id = azurerm_subnet.frontend-subnet.id
  }
}
resource "azurerm_lb_backend_address_pool" "lb-1-bepool" {
  loadbalancer_id     = azurerm_lb.lb-1.id
  name                = "lb-1-bepool"
}
resource "azurerm_network_interface_backend_address_pool_association" "lb-1-backend-1" {
  network_interface_id    = azurerm_network_interface.backend-1-nic.id
  ip_configuration_name   = "backend-1-ipconfig"
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb-1-bepool.id
}
#resource "azurerm_network_interface_backend_address_pool_association" "lb-1-backend-2" {
#  network_interface_id    = azurerm_network_interface.backend-2-nic.id
#  ip_configuration_name   = "backend-2-ipconfig"
#  backend_address_pool_id = azurerm_lb_backend_address_pool.lb-1-bepool.id
#}
resource "azurerm_lb_rule" "lb-1-rule1" {
  resource_group_name   = azurerm_resource_group.privatelink-service-rg.name
  loadbalancer_id                = azurerm_lb.lb-1.id
  name                           = "lb-1-rule1"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "lb-1-frontend-ipconfig"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.lb-1-bepool.id
  probe_id                       = azurerm_lb_probe.lb-1-probe.id
}
resource "azurerm_lb_rule" "lb-1-rule2" {
  resource_group_name   = azurerm_resource_group.privatelink-service-rg.name
  loadbalancer_id                = azurerm_lb.lb-1.id
  name                           = "lb-1-rule2"
  protocol                       = "Tcp"
  frontend_port                  = 5201
  backend_port                   = 5201
  frontend_ip_configuration_name = "lb-1-frontend-ipconfig"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.lb-1-bepool.id
  probe_id                       = azurerm_lb_probe.lb-1-probe.id
}
resource "azurerm_lb_rule" "lb-1-rule3" {
  resource_group_name   = azurerm_resource_group.privatelink-service-rg.name
  loadbalancer_id                = azurerm_lb.lb-1.id
  name                           = "lb-1-rule3"
  protocol                       = "Udp"
  frontend_port                  = 5201
  backend_port                   = 5201
  frontend_ip_configuration_name = "lb-1-frontend-ipconfig"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.lb-1-bepool.id
  probe_id                       = azurerm_lb_probe.lb-1-probe.id
}
resource "azurerm_lb_probe" "lb-1-probe" {
  resource_group_name   = azurerm_resource_group.privatelink-service-rg.name
  loadbalancer_id     = azurerm_lb.lb-1.id
  name                = "http-running-probe"
  port                = 80
}
#######################################################################
## Create Privatelink Service plsrv-1
#######################################################################
resource "azurerm_private_link_service" "plsrv-1" {
  name                  = "plsrv-1"
  resource_group_name   = azurerm_resource_group.privatelink-service-rg.name
  location              = var.location-privatelink-service

  auto_approval_subscription_ids              = ["0245be41-c89b-4b46-a3cc-a705c90cd1e8"]
  visibility_subscription_ids               = ["0245be41-c89b-4b46-a3cc-a705c90cd1e8"]
  load_balancer_frontend_ip_configuration_ids = [azurerm_lb.lb-1.frontend_ip_configuration.0.id]

    nat_ip_configuration {
    name                       = "primary"
    private_ip_address_version = "IPv4"
    subnet_id                  = azurerm_subnet.nat-subnet.id
    primary                    = true
  }
}
#######################################################################
## Create Storage privatelink-blob
#######################################################################
resource "random_string" "st-acc"{
  length = 12
  upper = false
  special = false
}
resource "azurerm_storage_account" "privatelink-blob-mdd" {
  name                = random_string.st-acc.result
  resource_group_name = azurerm_resource_group.privatelink-service-rg.name

  location                 = var.location-privatelink-service
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
 tags = {
    environment = "pl-service"
    deployment  = "terraform"
    microhack    = "privatelink-routing"
  }
}
resource "azurerm_storage_container" "content" {
  name                  = "content"
  storage_account_name  = azurerm_storage_account.privatelink-blob-mdd.name
  container_access_type = "private"
}
