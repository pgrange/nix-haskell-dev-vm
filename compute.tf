resource "google_compute_instance" "haskell-dev-vm" {
  project      = "pankzsoft-terraform-admin"
  name         = "haskell-dev-vm-1"
  # custom
  machine_type = "custom-6-40960"
  allow_stopping_for_update = true

  tags = [ "dev-vm" ]

  metadata = {
    sshKeys = file("ssh_keys")
  }

  boot_disk {
    initialize_params {
      size  = 50
      image = "dev-1610564199"
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
    }
  }
}

output "instance_id" {
  value = google_compute_instance.haskell-dev-vm.self_link
}

output "instance_ip" {
  value = google_compute_instance.haskell-dev-vm.network_interface.0.access_config.0.nat_ip
}
