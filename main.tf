terraform {
  required_version = ">= 1.2"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.42"
    }
  }
}

locals {
  labels = merge({
    module = "restricted-apis-dns"
  }, var.labels)
  zones = { for z in var.overrides : replace(format("%s-%s", var.name, z), "/[^a-zA-Z0-9]/", "-") => trimsuffix(z, ".") }
}

module "restrictedapis" {
  source                             = "terraform-google-modules/cloud-dns/google"
  version                            = "4.2.1"
  project_id                         = var.project_id
  type                               = "private"
  name                               = format("%s-googleapis", var.name)
  description                        = "Override googleapis.com domain to use restricted.googleapis.com endpoints"
  domain                             = "googleapis.com."
  private_visibility_config_networks = var.network_self_links
  labels                             = local.labels
  recordsets = [
    {
      name = "*"
      type = "CNAME"
      ttl  = 300
      records = [
        "restricted.googleapis.com.",
      ]
    },
    {
      name = "restricted"
      type = "A"
      ttl  = 300
      records = [
        "199.36.153.4",
        "199.36.153.5",
        "199.36.153.6",
        "199.36.153.7",
      ]
    }
  ]
}

module "zones" {
  for_each                           = local.zones
  source                             = "terraform-google-modules/cloud-dns/google"
  version                            = "4.2.1"
  project_id                         = var.project_id
  type                               = "private"
  name                               = each.key
  description                        = format("Override %s domain to use restricted.googleapis.com private endpoints", each.value)
  domain                             = format("%s.", each.value)
  private_visibility_config_networks = var.network_self_links
  labels                             = local.labels
  recordsets = [
    {
      name = "*"
      type = "CNAME"
      ttl  = 300
      records = [
        "restricted.googleapis.com.",
      ]
    },
    {
      name = "",
      type = "A"
      ttl  = 300
      records = [
        "199.36.153.4",
        "199.36.153.5",
        "199.36.153.6",
        "199.36.153.7",
      ]
    },
  ]
}
