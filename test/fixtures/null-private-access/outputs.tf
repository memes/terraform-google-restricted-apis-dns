output "network_self_links_json" {
  value = "[]"
}

output "overrides_json" {
  value = jsonencode(var.overrides)
}

output "labels_json" {
  value = jsonencode(var.labels)
}

output "addresses_json" {
  value = jsonencode(null)
}

output "use_private_access_endpoints" {
  value = null
}

output "description" {
  value = "Override DNS entries for Google APIs access"
}
