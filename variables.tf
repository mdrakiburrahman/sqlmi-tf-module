//
// variables
//
variable "resource_group_name" {
  description = "Deployment RG name."
  default     = "e-coretest-ccoe-cia0-sqlmi-poc-rg-1"
}
variable "resource_group_location" {
  description = "The location in which the deployment is taking place."
  default     = "canadacentral"
}
variable "mi_name" {}
variable "vnet_name" {}
variable "vnet_address_prefix" {}
variable "mi_subnet_name" {}
variable "mi_subnet_address_prefix" {}
variable "sqlmi_administrator_login" {}
variable "sqlmi_administrator_password" {}
variable "sqlmi_public_data_endpoint_enabled" {}
