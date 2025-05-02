terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.27"
    }
  }
}

locals {
  zones                        = { for z in distinct(concat(["googleapis.com"], var.overrides == null ? [] : var.overrides)) : replace(format("%s-%s", var.name, z), "/[^a-zA-Z0-9]/", "-") => trimsuffix(z, ".") }
  use_private_access_endpoints = try(var.use_private_access_endpoints, false)
  custom_ipv4_addresses        = try(length(var.addresses.ipv4), 0) > 0 ? var.addresses.ipv4 : []
  custom_ipv6_addresses        = try(length(var.addresses.ipv6), 0) > 0 ? var.addresses.ipv6 : []
  use_custom_addresses         = length(local.custom_ipv4_addresses) + length(local.custom_ipv6_addresses) > 0
  # If any IPv4 or IPv6 address is present in `addresses` then those should be used for IPv4 and IPv6 resource records
  # even if the set is empty.
  rrdatas_ipv4 = local.use_custom_addresses ? local.custom_ipv4_addresses : (local.use_private_access_endpoints ? [
    "199.36.153.8",
    "199.36.153.9",
    "199.36.153.10",
    "199.36.153.11",
    ] : [
    "199.36.153.4",
    "199.36.153.5",
    "199.36.153.6",
    "199.36.153.7",
  ])
  rrdatas_ipv6 = local.use_custom_addresses ? local.custom_ipv6_addresses : (local.use_private_access_endpoints ? [
    "2600:2d00:0002:2000::",
    ] : [
    "2600:2d00:0002:1000::",
  ])
}

resource "google_dns_managed_zone" "zone" {
  for_each      = local.zones
  project       = var.project_id
  name          = each.key
  description   = coalesce(var.description, "Override DNS entries for Google APIs access")
  dns_name      = format("%s.", each.value)
  labels        = var.labels
  visibility    = "private"
  force_destroy = false

  dynamic "private_visibility_config" {
    for_each = try(length(var.network_self_links), 0) > 0 ? [1] : []
    content {
      dynamic "networks" {
        for_each = var.network_self_links
        content {
          network_url = networks.value
        }
      }
    }
  }
}

resource "google_dns_record_set" "zone_cname" {
  for_each     = google_dns_managed_zone.zone
  project      = var.project_id
  managed_zone = each.value.name
  name         = format("*.%s", each.value.dns_name)
  type         = "CNAME"
  ttl          = 300
  rrdatas = [
    format("%s", each.value.dns_name),
  ]

  depends_on = [
    google_dns_managed_zone.zone,
  ]
}

resource "google_dns_record_set" "zone_a" {
  for_each     = { for k, v in google_dns_managed_zone.zone : k => v if length(local.rrdatas_ipv4) > 0 }
  project      = var.project_id
  managed_zone = each.value.name
  name         = each.value.dns_name
  type         = "A"
  ttl          = 300
  rrdatas      = local.rrdatas_ipv4

  depends_on = [
    google_dns_managed_zone.zone,
  ]
}

resource "google_dns_record_set" "zone_aaaa" {
  for_each     = { for k, v in google_dns_managed_zone.zone : k => v if length(local.rrdatas_ipv6) > 0 }
  project      = var.project_id
  managed_zone = each.value.name
  name         = each.value.dns_name
  type         = "AAAA"
  ttl          = 300
  rrdatas      = local.rrdatas_ipv6

  depends_on = [
    google_dns_managed_zone.zone,
  ]
}
