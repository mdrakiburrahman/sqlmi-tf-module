<!-- PROJECT LOGO -->
<p align="center">
  <img src="docs/images/logo.png" alt="Logo">
  <h3 align="center">Azure SQL Managed Instance - Terraform</h3>
  <p align="center">
    Terraform modules for Azure SQL MI deployment
    <br />
    <br />
    <a href="https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/sql_managed_instance">Terraform Docs</a>
    ·
    <a href="https://docs.microsoft.com/en-us/azure/azure-sql/managed-instance/how-to-content-reference-guide">Microsoft Docs</a>
  </p>
</p>

## Table of Contents <!-- omit in toc -->

- [Overview](#overview)
- [Variables](#variables)
- [Deployment times](#deployment-times)
  - [First time MI deployment (~3 hours)](#first-time-mi-deployment-3-hours)
  - [Second MI deployment (~21 mins)](#second-mi-deployment-21-mins)
- [TFE API](#tfe-api)
- [Notes](#notes)

## Overview

This Terraform module currently deploys the following resources (tested with Terraform Enterprise):

- Azure Resource Group
- Azure Virtual Network
- Dedicated Subnet for SQL MI
- Network Security Group with the [mandatory](https://docs.microsoft.com/en-us/azure/azure-sql/managed-instance/connectivity-architecture-overview#mandatory-inbound-security-rules-with-service-aided-subnet-configuration) and some recommended inbound and outbound rules applied
- Azure Route table (managed by SQL MI Management Plane)

Azure resources deployed:
![Deployed Azure Resources](docs/images/1.png)

Terraform resources deployed:
![Deployed TF Resources](docs/images/2.png)

## Variables

| Name                               | Example               | Description                                                                                                                          |
| ---------------------------------- | --------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| mi_name                            | aiasqlmik8s01         | Name of the sql managed instance. Lowercase letters and numbers.                                                                     |
| vnet_name                          | vnet                  | Name of the virtual network. Lowercase letters and numbers.                                                                          |
| vnet_address_prefix                | 10.0.0.0/16           | Virtual Network CIDR range                                                                                                           |
| mi_subnet_name                     | MySQLManagedInstance  | Name of SQL MI Subnet                                                                                                                |
| mi_subnet_address_prefix           | 10.0.0.0/24           | SQL MI Subnet CIDR range                                                                                                             |
| sqlmi_administrator_login          | admin                 | SQL MI admin login                                                                                                                   |
| sqlmi_administrator_password       | myCompl3xPassword!123 | SQL MI admin password                                                                                                                |
| sqlmi_public_data_endpoint_enabled | false                 | Configure [SQL MI Public Endpoint/FQDN](https://docs.microsoft.com/en-us/azure/azure-sql/managed-instance/public-endpoint-configure) |
| resource_group_name                | my-rg-1               | Name of Azure Resource Group                                                                                                                                     |
| resource_group_location            | canadacentral         | Location of Azure Resource Group and subsequent resources                                                                                                                                     |

## Deployment times

First time SQL MI deployments creates a [Virtual Cluster](https://techcommunity.microsoft.com/t5/azure-sql-blog/azure-sql-mi-now-removes-virtual-cluster-as-part-of-the-delete/ba-p/2703627) inside the Customer VNET - which is a long running operation - see 90th percentile durations documented [here](https://docs.microsoft.com/en-ca/azure/azure-sql/managed-instance/management-operations-overview#duration).

For example - some durations from a TFE deployment are documented below

### First time MI deployment (~3 hours)
![First Time MI deployment](docs/images/4.png) 

### Second MI deployment (~21 mins)
![Second Time MI deployment](docs/images/5.png) 


## TFE API

The following commands are useful for [`refresh only`](https://www.terraform.io/docs/cli/commands/refresh.html) and [`destroy`](https://www.terraform.io/docs/cli/commands/destroy.html) runs in TFE:

``` bash
# Refresh Only
curl --location --request POST 'https://your--tfe--url.com/api/v2/runs' \
--header 'Content-Type: application/vnd.api+json' \
--header 'Authorization: Bearer your--tfe--api--token' \
--data-raw '{
  "data": {
    "attributes": {
      "refresh-only": true
    },
    "type":"runs",
    "relationships": {
      "workspace": {
        "data": {
          "type": "workspaces",
          "id": "ws-xxx"
        }
      }
    }
  }
}'

# Destroy
curl --location --request POST 'https://your--tfe--url.com/api/v2/runs' \
--header 'Content-Type: application/vnd.api+json' \
--header 'Authorization: Bearer your--tfe--api--token' \
--data-raw '{
  "data": {
    "attributes": {
      "is-destroy": true
    },
    "type":"runs",
    "relationships": {
      "workspace": {
        "data": {
          "type": "workspaces",
          "id": "ws-xxx"
        }
      }
    }
  }
}'

```

## Notes

- Currently, this module only works with Terraform CLI (locally), or Terraform Enterprise.

  Terraform Cloud has a 2 hour apply timeout that causes the deployment to time out:
  ![Timeout with TF Cloud](docs/images/3.png)

- In case you plan to create new instance in the same subnet (MI2) and remove the old one (MI1), first create the new instance (MI2), and **then** remove the old one (MI1). New instance creation in the same subnet will (in most cases) trigger virtual cluster resize operation which is faster than buildout operation triggered on first instance creation. After that, remove the old one - see [here](https://docs.microsoft.com/en-ca/azure/azure-sql/managed-instance/management-operations-overview#duration)