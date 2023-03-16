terraform {
  required_version = ">= 1.2"
}

resource "google_compute_network" "test" {
  project                 = var.project_id
  name                    = var.name
  description             = "Test VPC network for restricted-api DNS testing"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

module "test" {
  source     = "./../../../"
  project_id = var.project_id
  name       = var.name
  overrides  = var.overrides
  labels     = var.labels
  network_self_links = [
    google_compute_network.test.self_link,
  ]
}
