resource "azurerm_resource_group" "rgroup" {
  name     = "grainlogisticproject"
  location = "East US"

}

resource "azurerm_storage_account" "stracc" {
  name                     = "grainlogisticslake"
  location                 = azurerm_resource_group.rgroup.location
  resource_group_name      = azurerm_resource_group.rgroup.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true

}

resource "azurerm_role_assignment" "user_storage_contributor" {
  scope                = azurerm_storage_account.stracc.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.principal_id

  depends_on = [azurerm_storage_account.stracc]
}

resource "azurerm_storage_container" "containergrain" {
  name                  = "grain"
  storage_account_name  = azurerm_storage_account.stracc.name
  container_access_type = "private"
}

resource "azurerm_storage_data_lake_gen2_path" "inbound" {
  storage_account_id = azurerm_storage_account.stracc.id
  filesystem_name    = azurerm_storage_container.containergrain.name
  path               = "inbound"
  resource           = "directory"

  depends_on = [
    azurerm_role_assignment.user_storage_contributor
  ]

}

resource "azurerm_storage_data_lake_gen2_path" "bronze" {
  storage_account_id = azurerm_storage_account.stracc.id
  filesystem_name    = azurerm_storage_container.containergrain.name
  path               = "bronze"
  resource           = "directory"

  depends_on = [
    azurerm_role_assignment.user_storage_contributor
  ]

}

resource "azurerm_storage_data_lake_gen2_path" "silver" {
  storage_account_id = azurerm_storage_account.stracc.id
  filesystem_name    = azurerm_storage_container.containergrain.name
  path               = "silver"
  resource           = "directory"

  depends_on = [
    azurerm_role_assignment.user_storage_contributor
  ]

}

resource "azurerm_storage_data_lake_gen2_path" "gold" {
  storage_account_id = azurerm_storage_account.stracc.id
  filesystem_name    = azurerm_storage_container.containergrain.name
  path               = "gold"
  resource           = "directory"

  depends_on = [
    azurerm_role_assignment.user_storage_contributor
  ]

}


resource "random_string" "naming" {
  special = false
  upper   = false
  length  = 6
}

locals {
  prefix = "grainlogisticdatabricks${random_string.naming.result}"
}

resource "azurerm_databricks_workspace" "databricks_workspace" {
  name                        = "${local.prefix}-workspace"
  resource_group_name         = azurerm_resource_group.rgroup.name
  location                    = azurerm_resource_group.rgroup.location
  sku                         = "trial"
  managed_resource_group_name = "${local.prefix}-workspace-rg"

}


resource "azurerm_databricks_access_connector" "dac" {
  name                = "databricks-access-connector-grain"
  resource_group_name = azurerm_resource_group.rgroup.name
  location            = azurerm_resource_group.rgroup.location
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "dac_storage_contributor" {
  scope                = azurerm_storage_account.stracc.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.dac.identity[0].principal_id
}

resource "databricks_user" "felipe_user" {
  user_name             = "felipegoraro@outlook.com"
  display_name          = "Felipe Pegoraro"
  workspace_access      = true
  databricks_sql_access = true
  allow_cluster_create  = true
}

resource "databricks_cluster" "dtb_cluster" {
  cluster_name            = "admin"
  spark_version           = "15.4.x-scala2.12"
  node_type_id            = "Standard_D4s_v3"
  driver_node_type_id     = "Standard_D4s_v3"
  autotermination_minutes = 10
  enable_elastic_disk     = true
  single_user_name        = databricks_user.felipe_user.user_name
  data_security_mode      = "SINGLE_USER"
  runtime_engine          = "PHOTON"

  autoscale {
    min_workers = 1
    max_workers = 2
  }

}

resource "databricks_notebook" "notebook_pipeline" {
  source = var.notebooks_source_pipeline_path
  path   = var.notebooks_target_pipeline_path
}

resource "databricks_notebook" "notebook_performance" {
  source = var.notebooks_source_performance_path
  path   = var.notebooks_target_performance_path
}

resource "databricks_notebook" "notebook_systemtables" {
  source = var.notebooks_source_systemtables_path
  path   = var.notebooks_target_systemtables_path
}

resource "databricks_notebook" "notebook_cluster_create" {
  source = var.notebooks_source_cluster_create_path
  path   = var.notebooks_target_cluster_create_path
}
