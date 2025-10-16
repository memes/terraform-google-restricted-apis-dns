terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.27"
    }
  }
}

resource "google_compute_network" "test" {
  for_each                = var.names == null ? {} : { for name in var.names : name => true }
  project                 = var.project_id
  name                    = each.key
  description             = "Test VPC network for restricted-api DNS testing"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}
