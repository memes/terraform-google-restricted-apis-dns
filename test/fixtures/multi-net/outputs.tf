output "network_self_links_json" {
  value = jsonencode([google_compute_network.test1.self_link, google_compute_network.test2.self_link])
}

output "overrides_json" {
  value = jsonencode(var.overrides)
}

output "labels_json" {
  value = jsonencode(merge({
    module = "restricted-apis-dns"
  }, var.labels))
}
