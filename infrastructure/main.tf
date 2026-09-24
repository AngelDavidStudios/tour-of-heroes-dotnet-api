# Terraform state in Azure Storage
terraform {
  backend "azurerm" {
    key = "tour-of-heroes-tf-state"
  }
}

# Azure provider
provider "azurerm" {
  features {}
}

# Variables
variable "db_user" {
  description = "Database administrator username"
  type        = string
}

variable "db_password" {
  description = "Database administrator password"
  type        = string
  sensitive   = true
}

variable "database_provider" {
  description = "Database provider to use (SqlServer or PostgreSQL)"
  type        = string
  default     = "SqlServer"
  validation {
    condition     = contains(["SqlServer", "PostgreSQL"], var.database_provider)
    error_message = "database_provider must be either SqlServer or PostgreSQL"
  }
}

variable "postgresql_admin_password" {
  description = "Administrator password for PostgreSQL"
  type        = string
  sensitive   = true
  default     = null
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "tour-of-heroes"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

# Local variables for common tags
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
  
  # PostgreSQL password (use specific password if provided, otherwise use db_password)
  postgresql_password = var.postgresql_admin_password != null ? var.postgresql_admin_password : var.db_password
}


# Resource group
resource "azurerm_resource_group" "rg" {
  name     = "Tour-Of-Heroes"
  location = "North Europe"
}


# Create an Azure SQL Server (conditional)
resource "azurerm_mssql_server" "sqlserver" {
  count                        = var.database_provider == "SqlServer" ? 1 : 0
  name                         = "heroserver"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = var.db_user
  administrator_login_password = var.db_password

  tags = local.common_tags
}

# Allow Azure services and resources to access this server
resource "azurerm_mssql_firewall_rule" "sqlserver" {
  count            = var.database_provider == "SqlServer" ? 1 : 0
  name             = "allow-azure-services"
  server_id        = azurerm_mssql_server.sqlserver[0].id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Create a database
resource "azurerm_mssql_database" "sqldatabase" {
  count     = var.database_provider == "SqlServer" ? 1 : 0
  name      = "heroes"
  server_id = azurerm_mssql_server.sqlserver[0].id
  sku_name  = "Basic"

  tags = local.common_tags
}

# PostgreSQL Flexible Server (conditional)
resource "azurerm_postgresql_flexible_server" "heroes" {
  count               = var.database_provider == "PostgreSQL" ? 1 : 0
  name                = "psql-${var.project_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  
  administrator_login    = var.db_user
  administrator_password = local.postgresql_password
  
  sku_name   = "B_Standard_B1ms"
  version    = "16"
  storage_mb = 32768  # 32 GB - minimum for Flexible Server
  
  zone = "1"

  tags = local.common_tags
}

# PostgreSQL Database
resource "azurerm_postgresql_flexible_server_database" "heroes" {
  count     = var.database_provider == "PostgreSQL" ? 1 : 0
  name      = "heroes"
  server_id = azurerm_postgresql_flexible_server.heroes[0].id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

# Firewall rule for Azure Services
resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure" {
  count            = var.database_provider == "PostgreSQL" ? 1 : 0
  name             = "AllowAzureServices"
  server_id        = azurerm_postgresql_flexible_server.heroes[0].id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Azure App Service Plan
resource "azurerm_service_plan" "plan" {
  name                = "tour-of-heroes-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # sku {
  #   tier = "Standard"
  #   size = "S1"
  # }

  os_type = "Windows"

  sku_name = "S1"
}

# Create Web App
resource "azurerm_windows_web_app" "web" {
  name                = "tour-of-heroes-webapi"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  service_plan_id = azurerm_service_plan.plan.id

  site_config {
    application_stack {
      current_stack  = "dotnetcore"
      dotnet_version = "v9.0"
    }
  }

  app_settings = {
    "DATABASE_PROVIDER" = var.database_provider
  }

  # Connection Strings
  dynamic "connection_string" {
    for_each = var.database_provider == "SqlServer" ? [1] : []
    content {
      name  = "DefaultConnection"
      value = "Server=tcp:${azurerm_mssql_server.sqlserver[0].name}.database.windows.net,1433;Initial Catalog=${azurerm_mssql_database.sqldatabase[0].name};Persist Security Info=False;User ID=${var.db_user};Password=${var.db_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
      type  = "SQLAzure"
    }
  }

  dynamic "connection_string" {
    for_each = var.database_provider == "PostgreSQL" ? [1] : []
    content {
      name  = "PostgreSQL"
      value = "Host=${azurerm_postgresql_flexible_server.heroes[0].fqdn};Database=heroes;Username=${var.db_user};Password=${local.postgresql_password};SSL Mode=Require;"
      type  = "Custom"
    }
  }
}

# Create Web App slot
resource "azurerm_windows_web_app_slot" "web" {
  name = "staging"

  app_service_id = azurerm_windows_web_app.web.id

  app_settings = {
    "DATABASE_PROVIDER" = var.database_provider
  }

  # Connection Strings
  dynamic "connection_string" {
    for_each = var.database_provider == "SqlServer" ? [1] : []
    content {
      name  = "DefaultConnection"
      value = "Server=tcp:${azurerm_mssql_server.sqlserver[0].name}.database.windows.net,1433;Initial Catalog=${azurerm_mssql_database.sqldatabase[0].name};Persist Security Info=False;User ID=${var.db_user};Password=${var.db_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
      type  = "SQLAzure"
    }
  }

  dynamic "connection_string" {
    for_each = var.database_provider == "PostgreSQL" ? [1] : []
    content {
      name  = "PostgreSQL"
      value = "Host=${azurerm_postgresql_flexible_server.heroes[0].fqdn};Database=heroes;Username=${var.db_user};Password=${local.postgresql_password};SSL Mode=Require;"
      type  = "Custom"
    }
  }

  site_config {
    application_stack {
      current_stack  = "dotnetcore"
      dotnet_version = "v9.0"
    }
  }
}
