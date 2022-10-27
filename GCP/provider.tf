variable "google_provider_file" {}

provider "google" {
  credentials = var.google_provider_file
  region = "europe-west1"
  zone = "europe-west1-b"
  project = "iog-hydra"
}
