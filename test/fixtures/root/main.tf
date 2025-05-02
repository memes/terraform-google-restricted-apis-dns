terraform {
  required_version = ">= 1.5"
}

module "test" {
  source                       = "./../../../"
  project_id                   = var.project_id
  name                         = var.name
  description                  = var.description
  overrides                    = var.overrides
  labels                       = var.labels
  network_self_links           = []
  use_private_access_endpoints = var.use_private_access_endpoints
  addresses                    = var.addresses
}
