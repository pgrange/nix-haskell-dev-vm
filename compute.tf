variable "cachix_authentication" {}
variable "use_snapshot" {}

resource "google_compute_disk" "haskell-dev-vm-image" {
  count = var.use_snapshot == 1 ? 0 : 1
  name  = "haskell-dev-vm-disk-image"
  type  = "pd-ssd"
  zone  = "europe-west4-b"
  size  = 200
  image = "iog-hydra-1637229888"
  labels = {
    environment = "dev"
  }
}

resource "google_compute_disk" "haskell-dev-vm-snapshot" {
  count = var.use_snapshot == 1 ? 1 : 0
  name  = "haskell-dev-vm-disk-snapshot"
  type  = "pd-ssd"
  zone  = "europe-west4-b"
  size  = 200
  snapshot = var.use_snapshot == 1 ? "iog-hydra-dev-vm-snapshot" : ""
  labels = {
    environment = "dev"
  }
}

resource "google_compute_instance" "haskell-dev-vm" {
  name         = "haskell-dev-vm-1"

  # For faster CPUs
  # see https://cloud.google.com/compute/docs/compute-optimized-machines
  machine_type = "c2-standard-4"
  allow_stopping_for_update = true

  tags = [ "dev-vm" ]

  metadata = {
    sshKeys = file("ssh_keys")
  }

  boot_disk {
    source = var.use_snapshot == 1 ? google_compute_disk.haskell-dev-vm-snapshot[0].self_link : google_compute_disk.haskell-dev-vm-image[0].self_link
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
    }
  }

  provisioner "file" {
    source      = "scripts/configure.sh"
    destination = "/home/curry/configure.sh"

    connection {
      type = "ssh"
      user = "curry"
      host = self.network_interface.0.access_config.0.nat_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/curry/configure.sh",
      "CACHIX_AUTHENTICATION=${var.cachix_authentication} /home/curry/configure.sh"
    ]

    connection {
      type = "ssh"
      user = "curry"
      host = self.network_interface.0.access_config.0.nat_ip
    }
  }

}

output "instance_id" {
  value = google_compute_instance.haskell-dev-vm.self_link
}

output "project" {
  value = google_compute_instance.haskell-dev-vm.project
}

output "instance_ip" {
  value = google_compute_instance.haskell-dev-vm.network_interface.0.access_config.0.nat_ip
}

output "has_snapshot" {
  value = var.use_snapshot
  description = "Whether (1) or not (0) to use snapshot when creating VM"
}
