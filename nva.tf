#######################################################################
## Create Network Interface - nva-1-nic
#######################################################################
resource "azurerm_network_interface" "nva-1-nic" {
  name                 = "nva-1-nic"
  location             = var.location-privatelink-endpoint
  resource_group_name  = azurerm_resource_group.privatelink-endpoint-rg.name
  enable_ip_forwarding = false

  ip_configuration {
    name                          = "nva-1-ipconfig"
    subnet_id                     = azurerm_subnet.fw-1-ple-subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    environment = "pl-endpoint"
    deployment  = "terraform"
    microhack   = "privatelink-routing"
  }
}
#######################################################################
## Create Network Interface - nva-2-nic
#######################################################################
resource "azurerm_network_interface" "nva-2-nic" {
  name                 = "nva-2-nic"
  location             = var.location-privatelink-endpoint
  resource_group_name  = azurerm_resource_group.privatelink-endpoint-rg.name
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "nva-2-ipconfig"
    subnet_id                     = azurerm_subnet.fw-2-ple-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = {
    environment = "pl-endpoint"
    deployment  = "terraform"
    microhack   = "privatelink-routing"
  }
}
#######################################################################
## Create Virtual Machine nva-1-vm
#######################################################################
resource "azurerm_windows_virtual_machine" "nva-1-vm" {
  name                  = "nva-1-vm"
  location              = var.location-privatelink-endpoint
  resource_group_name   = azurerm_resource_group.privatelink-endpoint-rg.name
  network_interface_ids = [azurerm_network_interface.nva-2-nic.id]
  size               = var.vmsize
  computer_name  = "nva-1-vm"
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
    name              = "nva-1-osdisk"
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
## Create Virtual Machine nva-2-vm
#######################################################################
resource "azurerm_windows_virtual_machine" "nva-2-vm" {
  name                  = "nva-2-vm"
  location              = var.location-privatelink-endpoint
  resource_group_name   = azurerm_resource_group.privatelink-endpoint-rg.name
  network_interface_ids = [azurerm_network_interface.nva-2-nic.id]
  size               = var.vmsize
  computer_name  = "nva-2-vm"
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
    name              = "nva-2-osdisk"
    caching           = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }
  
  tags = {
    environment = "pl-endpoint"
    deployment  = "terraform"
    microhack   = "privatelink-routing"
  }
}
##########################################################
## Enable routing on nva-1-vm
##########################################################
resource "azurerm_virtual_machine_extension" "enable-routing-nva-1-vm" {
    
  name                 = "enable-routing-nva-1-vm"
  virtual_machine_id   = azurerm_windows_virtual_machine.nva-1-vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

   settings = <<SETTINGS
    {
        "commandToExecute":"powershell -ExecutionPolicy Unrestricted Set-NetIPInterface -Forwarding Enabled; powershell -ExecutionPolicy Unrestricted Set-NetfirewallRule -Name FPS-ICMP6-ERQ-In -Enable True -Profile Any"
    }
SETTINGS
}
##########################################################
## Enable routing on nva-2-vm
##########################################################
resource "azurerm_virtual_machine_extension" "enable-routing-nva-2-vm" {
    
  name                 = "enable-routing-nva-2-vm"
  virtual_machine_id   = azurerm_windows_virtual_machine.nva-2-vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

   settings = <<SETTINGS
    {
        "commandToExecute":"powershell -ExecutionPolicy Unrestricted Set-NetIPInterface -Forwarding Enabled; powershell -ExecutionPolicy Unrestricted Set-NetfirewallRule -Name FPS-ICMP6-ERQ-In -Enable True -Profile Any"
    }
SETTINGS
}