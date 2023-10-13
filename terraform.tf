terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.75.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "random_integer" "ri" {
    min = 10000
    max = 99999
}

resource "azurerm_resource_group" "rg" {
  name     = "TaskBoardRG${random_integer.ri.result}"
  location = "West Europe"
}

resource "azurerm_service_plan" "plan" {
  name                = "taskboard-${random_integer.ri.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "F1"
}

resource "azurerm_linux_web_app" "app" {
  name                = "taskboard"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_service_plan.plan.location
  service_plan_id     = azurerm_service_plan.plan.id

  site_config {
    application_stack {
      dotnet_version = "6.0"
    }
    always_on = false
  }
}

resource "azurerm_app_service_source_control" "git" {
  app_id   = azurerm_linux_web_app.app.id
  repo_url = "https://github.com/ggrotseva/TaskBoard"
  branch   = "master"
  use_manual_integration = true
}

resource "azurerm_mssql_server" "mssql" {
  name                         = "mssqlserver"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = "admin"
  administrator_login_password = "Password12#"

  azuread_administrator {
    login_username = "AzureAD Admin"
    object_id      = "00000000-0000-0000-0000-000000000000"
  }

  tags = {
    environment = "production"
  }
}