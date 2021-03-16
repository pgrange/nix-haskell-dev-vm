variable "cachix_authentication" {}

resource "google_compute_instance" "haskell-dev-vm" {
  project      = "pankzsoft-terraform-admin"
  name         = "haskell-dev-vm-1"
  # custom type
  # RAM is a multiple of 256MB
  # 38400 = 256MB * 80
  machine_type = "custom-6-20480"
  allow_stopping_for_update = true

  tags = [ "dev-vm" ]

  metadata = {
    sshKeys = file("ssh_keys")
  }

  boot_disk {
    initialize_params {
      size  = 100
      image = "dev-1611918695"
    }
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

output "instance_ip" {
  value = google_compute_instance.haskell-dev-vm.network_interface.0.access_config.0.nat_ip
}
