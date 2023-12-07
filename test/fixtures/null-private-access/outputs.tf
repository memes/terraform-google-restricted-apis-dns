output "network_self_links_json" {
  value = "[]"
}

output "overrides_json" {
  value = jsonencode(var.overrides)
}

output "labels_json" {
  value = jsonencode(merge({
    module = "restricted-apis-dns"
  }, var.labels))
}
