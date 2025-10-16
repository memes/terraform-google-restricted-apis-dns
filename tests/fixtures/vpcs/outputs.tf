output "self_links" {
  value = [for vpc in google_compute_network.test : vpc.self_link]
}
