provider "azurerm" {
    features {}
}

# Initially referenced from: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/sql_managed_instance
resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.resource_group_location
}

# Virtual Network for MIs - can introduce Peering as required
resource "azurerm_virtual_network" "example" {
  name                = var.vnet_name
  resource_group_name = azurerm_resource_group.example.name
  address_space       = [var.vnet_address_prefix]
  location            = azurerm_resource_group.example.location
}

# Dedicated Subnet for MI: Mandatory
resource "azurerm_subnet" "example" {
  name                 = var.mi_subnet_name
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefix       = var.mi_subnet_address_prefix

  # Need to delegate to SQL MI RP
  delegation {
    name = "managedinstancedelegation"

    service_delegation {
      name    = "Microsoft.Sql/managedInstances"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action", "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"]
    }
  }
}

# NSG to contain MI specific requirements
resource "azurerm_network_security_group" "example" {
  name                = "mi-security-group"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

################
# Inbound rules
################

# Mandatory rules: https://docs.microsoft.com/en-us/azure/azure-sql/managed-instance/connectivity-architecture-overview#mandatory-inbound-security-rules-with-service-aided-subnet-configuration

resource "azurerm_network_security_rule" "allow_tds_inbound" {
  direction                   = "Inbound"
  priority                    = 1000
  name                        = "allow_tds_inbound"
  description                 = "Allow access to database"
  source_port_range           = "*"
  destination_port_ranges     = ["1433"]
  protocol                    = "TCP"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = var.mi_subnet_address_prefix
  access                      = "Allow"
  resource_group_name         = azurerm_resource_group.example.name
  network_security_group_name = azurerm_network_security_group.example.name
}

resource "azurerm_network_security_rule" "allow_redirect_inbound" {
  direction                   = "Inbound"
  priority                    = 1100
  name                        = "allow_redirect_inbound"
  description                 = "Allow inbound redirect traffic to Managed Instance inside the virtual network"
  source_port_range           = "*"
  destination_port_range      = "11000-11999"
  protocol                    = "TCP"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = var.mi_subnet_address_prefix
  access                      = "Allow"
  resource_group_name         = azurerm_resource_group.example.name
  network_security_group_name = azurerm_network_security_group.example.name
}

resource "azurerm_network_security_rule" "allow_geodr_inbound" {
  direction                   = "Inbound"
  priority                    = 1200
  name                        = "allow_geodr_inbound"
  description                 = "Allow inbound geodr (DAG) traffic inside the virtual network"
  source_port_range           = "*"
  destination_port_range      = "5022"
  protocol                    = "TCP"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = var.mi_subnet_address_prefix
  access                      = "Allow"
  resource_group_name         = azurerm_resource_group.example.name
  network_security_group_name = azurerm_network_security_group.example.name
}

# *** Temporary ***
resource "azurerm_network_security_rule" "allow_public_connect_temp" {
  direction                   = "Inbound"
  priority                    = 1300
  name                        = "allow_public_connect_temp"
  description                 = "Temporary Access Test with RBC CIDR ranges to test connectivity without Peering"
  source_port_range           = "*"
  destination_port_range      = "3342"
  protocol                    = "TCP"
  source_address_prefixes     = ["99.238.41.0/24", "99.237.57.0/24", "167.220.149.0/24"]
  destination_address_prefix  = var.mi_subnet_address_prefix
  access                      = "Allow"
  resource_group_name         = azurerm_resource_group.example.name
  network_security_group_name = azurerm_network_security_group.example.name
}

resource "azurerm_network_security_rule" "deny_all_inbound" {
  direction                   = "Inbound"
  priority                    = 4096
  name                        = "deny_all_inbound"
  description                 = "Deny all rest"
  source_port_range           = "*"
  destination_port_range      = "*"
  protocol                    = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  access                      = "Deny"
  resource_group_name         = azurerm_resource_group.example.name
  network_security_group_name = azurerm_network_security_group.example.name
}

################
# Outbound rules
################

# Mandatory rules: https://docs.microsoft.com/en-us/azure/azure-sql/managed-instance/connectivity-architecture-overview#mandatory-outbound-security-rules-with-service-aided-subnet-configuration

resource "azurerm_network_security_rule" "allow_linkedserver_outbound" {
  direction                   = "Outbound"
  priority                    = 1000
  name                        = "allow_linkedserver_outbound"
  description                 = "Allow outbound linkedserver traffic inside the virtual network"
  source_port_range           = "*"
  destination_port_range      = "1433" 
  protocol                    = "TCP"
  source_address_prefix       = var.mi_subnet_address_prefix
  destination_address_prefix  = "VirtualNetwork"
  access                      = "Allow"
  resource_group_name         = azurerm_resource_group.example.name
  network_security_group_name = azurerm_network_security_group.example.name
}

resource "azurerm_network_security_rule" "allow_redirect_outbound" {
  direction                   = "Outbound"
  priority                    = 1100
  name                        = "allow_redirect_outbound"
  description                 = "Allow outbound redirect traffic to Managed Instance inside the virtual network"
  source_port_range           = "*"
  destination_port_range      = "11000-11999" 
  protocol                    = "TCP"
  source_address_prefix       = var.mi_subnet_address_prefix
  destination_address_prefix  = "VirtualNetwork"
  access                      = "Allow"
  resource_group_name         = azurerm_resource_group.example.name
  network_security_group_name = azurerm_network_security_group.example.name
}

resource "azurerm_network_security_rule" "allow_geodr_outbound" {
  direction                   = "Outbound"
  priority                    = 1200
  name                        = "allow_geodr_outbound"
  description                 = "Allow outbound geodr traffic inside the virtual network"
  source_port_range           = "*"
  destination_port_range      = "5022" 
  protocol                    = "TCP"
  source_address_prefix       = var.mi_subnet_address_prefix
  destination_address_prefix  = "VirtualNetwork"
  access                      = "Allow"
  resource_group_name         = azurerm_resource_group.example.name
  network_security_group_name = azurerm_network_security_group.example.name
}

resource "azurerm_network_security_rule" "allow_privatelink_outbound" {
  direction                   = "Outbound"
  priority                    = 1300
  name                        = "allow_privatelink_outbound"
  description                 = "Allow outbound private link traffic inside the virtual network"
  source_port_range           = "*"
  destination_port_range      = "443" 
  protocol                    = "TCP"
  source_address_prefix       = var.mi_subnet_address_prefix
  destination_address_prefix  = "VirtualNetwork"
  access                      = "Allow"
  resource_group_name         = azurerm_resource_group.example.name
  network_security_group_name = azurerm_network_security_group.example.name
}

resource "azurerm_network_security_rule" "deny_all_outbound" {
  direction                   = "Outbound"
  priority                    = 4096
  name                        = "deny_all_outbound"
  description                 = "Deny all other outbound traffic"
  source_port_range           = "*"
  destination_port_range      = "*" 
  protocol                    = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  access                      = "Deny"
  resource_group_name         = azurerm_resource_group.example.name
  network_security_group_name = azurerm_network_security_group.example.name
}

# Associate to MI Subnet
resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = azurerm_subnet.example.id
  network_security_group_id = azurerm_network_security_group.example.id
}

################
# Route table
################
resource "azurerm_route_table" "example" {
  name                          = "routetable-mi"
  location                      = azurerm_resource_group.example.location
  resource_group_name           = azurerm_resource_group.example.name
  disable_bgp_route_propagation = false
  depends_on = [
    azurerm_subnet.example,
  ]

}

# Associate to MI Subnet
resource "azurerm_subnet_route_table_association" "example" {
  subnet_id      = azurerm_subnet.example.id
  route_table_id = azurerm_route_table.example.id
}

resource "azurerm_sql_managed_instance" "example1" {
  name                         = var.mi_name
  resource_group_name          = azurerm_resource_group.example.name
  location                     = azurerm_resource_group.example.location
  administrator_login          = var.sqlmi_administrator_login
  administrator_login_password = var.sqlmi_administrator_password
  license_type                 = "BasePrice"
  subnet_id                    = azurerm_subnet.example.id
  sku_name                     = "GP_Gen5"
  vcores                       = 4
  storage_size_in_gb           = 32
  public_data_endpoint_enabled = var.sqlmi_public_data_endpoint_enabled

  depends_on = [
    azurerm_subnet_network_security_group_association.example,
    azurerm_subnet_route_table_association.example,
  ]
}

output "sqlmi_fqdn" {
    value  = azurerm_sql_managed_instance.example1.fqdn
}

# Second MI for demonstration/time test
# resource "azurerm_sql_managed_instance" "example2" {
#   name                         = "${replace(var.mi_name, "1", "2")}"
#   resource_group_name          = azurerm_resource_group.example.name
#   location                     = azurerm_resource_group.example.location
#   administrator_login          = var.sqlmi_administrator_login
#   administrator_login_password = var.sqlmi_administrator_password
#   license_type                 = "BasePrice"
#   subnet_id                    = azurerm_subnet.example.id
#   sku_name                     = "GP_Gen5"
#   vcores                       = 4
#   storage_size_in_gb           = 32
#   public_data_endpoint_enabled = var.sqlmi_public_data_endpoint_enabled

#   depends_on = [
#     azurerm_subnet_network_security_group_association.example,
#     azurerm_subnet_route_table_association.example,
#   ]
# }

# Second MI for demonstration/time test
# output "sqlmi2_fqdn" {
#     value  = azurerm_sql_managed_instance.example2.fqdn
# }
