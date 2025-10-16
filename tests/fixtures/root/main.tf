terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.27"
    }
  }
}

module "test" {
  source                       = "./../../../"
  project_id                   = var.project_id
  name                         = var.name
  description                  = var.description
  overrides                    = var.overrides
  labels                       = var.labels
  network_self_links           = var.network_self_links
  use_private_access_endpoints = var.use_private_access_endpoints
  addresses                    = var.addresses
}
