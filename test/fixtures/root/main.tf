terraform {
  required_version = ">= 1.2"
}

module "test" {
  source                       = "./../../../"
  project_id                   = var.project_id
  name                         = var.name
  overrides                    = var.overrides
  labels                       = var.labels
  network_self_links           = []
  use_private_access_endpoints = var.use_private_access_endpoints
}
