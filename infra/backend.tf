terraform {
  backend "azurerm" {
    resource_group_name  = "sonarqube"
    storage_account_name = "tfbaceknd0009"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
  }
}