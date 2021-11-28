provider "azurerm" {
    features {}
}

variable "resource_group_name" {}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = "East US"
}

resource "azurerm_network_security_group" "example" {
  name                = "mi-security-group"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}
