resource "google_service_account" "hydra_builder" {
  account_id   = "hydra-builder"
  display_name = "Hydra Build agent"
}

resource "google_storage_bucket" "nix_cache_bucket" {
  name     = "nix-hydra-cache-bucket"
  location = "EU"
  force_destroy = true
  retention_policy {
    retention_period = 7889238 # three months
  }
}

resource "google_storage_bucket_iam_member" "hydra_builder_nix_cache_writer" {
  bucket = google_storage_bucket.nix_cache_bucket.name
  role = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.hydra_builder.email}"
}

resource "google_storage_bucket_iam_member" "hydra_builder_nix_cache_reader" {
  bucket = google_storage_bucket.nix_cache_bucket.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}
