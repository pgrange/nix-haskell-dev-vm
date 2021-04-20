variable "google_provider_file" {}

provider "google" {
  credentials = var.google_provider_file
  region = "europe-west4"
  zone = "europe-west4-b"
  project = "iog-hydra"
}
