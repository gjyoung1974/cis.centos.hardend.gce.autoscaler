output "pool_public_ip" {
  value = "${google_compute_forwarding_rule.acme.ip_address}"
}
