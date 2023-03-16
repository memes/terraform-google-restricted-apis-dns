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

resource "google_dns_managed_zone" "googleapis" {
  project       = var.project_id
  name          = format("%s-googleapis", var.name)
  description   = "Override googleapis.com domain to use restricted.googleapis.com endpoints"
  dns_name      = "googleapis.com."
  labels        = local.labels
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

resource "google_dns_record_set" "googleapis_cname" {
  project      = var.project_id
  managed_zone = google_dns_managed_zone.googleapis.name
  name         = "*.googleapis.com."
  type         = "CNAME"
  ttl          = 300
  rrdatas = [
    "restricted.googleapis.com.",
  ]
  depends_on = [
    google_dns_managed_zone.googleapis,
  ]
}

resource "google_dns_record_set" "googleapis_a" {
  project      = var.project_id
  managed_zone = google_dns_managed_zone.googleapis.name
  name         = "restricted.googleapis.com."
  type         = "A"
  ttl          = 300
  rrdatas = [
    "199.36.153.4",
    "199.36.153.5",
    "199.36.153.6",
    "199.36.153.7",
  ]
  depends_on = [
    google_dns_managed_zone.googleapis,
  ]
}

resource "google_dns_record_set" "googleapis_aaaa" {
  project      = var.project_id
  managed_zone = google_dns_managed_zone.googleapis.name
  name         = "restricted.googleapis.com."
  type         = "AAAA"
  ttl          = 300
  rrdatas = [
    "2600:2d00:2:1000::",
  ]
  depends_on = [
    google_dns_managed_zone.googleapis,
  ]
}

resource "google_dns_managed_zone" "overrides" {
  for_each      = local.zones
  project       = var.project_id
  name          = each.key
  description   = format("Override %s domain to use restricted.googleapis.com private endpoints", each.value)
  dns_name      = format("%s.", each.value)
  labels        = local.labels
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

resource "google_dns_record_set" "overrides_cname" {
  for_each     = google_dns_managed_zone.overrides
  project      = var.project_id
  managed_zone = each.value.name
  name         = format("*.%s", each.value.dns_name)
  type         = "CNAME"
  ttl          = 300
  rrdatas = [
    "restricted.googleapis.com.",
  ]
  depends_on = [
    google_dns_managed_zone.overrides,
  ]
}

resource "google_dns_record_set" "overrides_a" {
  for_each     = google_dns_managed_zone.overrides
  project      = var.project_id
  managed_zone = each.value.name
  name         = each.value.dns_name
  type         = "A"
  ttl          = 300
  rrdatas = [
    "199.36.153.4",
    "199.36.153.5",
    "199.36.153.6",
    "199.36.153.7",
  ]
  depends_on = [
    google_dns_managed_zone.overrides,
  ]
}

resource "google_dns_record_set" "overrides_aaaa" {
  for_each     = google_dns_managed_zone.overrides
  project      = var.project_id
  managed_zone = each.value.name
  name         = each.value.dns_name
  type         = "AAAA"
  ttl          = 300
  rrdatas = [
    "2600:2d00:2:1000::",
  ]
  depends_on = [
    google_dns_managed_zone.overrides,
  ]
}
