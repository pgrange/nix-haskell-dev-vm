provider "aws" {
  default_tags {
    tags = {
      environment = "dev-vm"
    }
  }
}
