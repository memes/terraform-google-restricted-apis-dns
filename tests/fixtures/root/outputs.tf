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
  value = jsonencode(var.addresses)
}

output "use_private_access_endpoints" {
  value = var.use_private_access_endpoints
}

output "description" {
  value = var.description
}
