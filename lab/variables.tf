variable "location-privatelink-service" {
  description = "Location to deploy privatelink service"
  type        = string
  default     = "WestEurope"
}
variable "location-privatelink-endpoint" {
  description = "Location to deploy privatelink endpoint"
  type        = string
  default     = "NorthEurope"
}
variable "location-privatelink-firewall" {
  description = "Location to deploy firewall"
  type        = string
  default     = "NorthEurope"
}
variable "username" {
  description = "Username for Virtual Machines"
  type        = string
  default     = "AzureAdmin"
}
variable "password" {
  description = "Virtual Machine password, must meet Azure complexity requirements"
   type        = string
   default     = "Privatelink21"
}
variable "vmsize" {
  description = "Size of the VMs"
  default     = "Standard_D2_v3"
}

