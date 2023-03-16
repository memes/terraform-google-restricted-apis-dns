output "network_self_link" {
  value = google_compute_network.test.self_link
}

output "overrides_json" {
  value = jsonencode(var.overrides)
}

output "labels_json" {
  value = jsonencode(merge({
    module = "restricted-apis-dns"
  }, var.labels))
}
