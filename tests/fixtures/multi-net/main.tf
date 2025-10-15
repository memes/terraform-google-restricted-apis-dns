terraform {
  required_version = ">= 1.5"
}

resource "google_compute_network" "test1" {
  project                 = var.project_id
  name                    = format("%s-1", var.name)
  description             = "Test VPC network for restricted-api DNS testing"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_network" "test2" {
  project                 = var.project_id
  name                    = format("%s-2", var.name)
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
    google_compute_network.test1.self_link,
    google_compute_network.test2.self_link,
  ]
  use_private_access_endpoints = var.use_private_access_endpoints
}
