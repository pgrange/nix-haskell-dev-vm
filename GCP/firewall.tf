resource "google_compute_firewall" "dev-machine-fw" {
  name    = "allow-machine-ssh"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["dev-machine"]
}
