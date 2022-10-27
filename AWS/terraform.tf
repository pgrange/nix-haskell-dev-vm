terraform {
  backend "s3" {
    bucket = "terraform-dev-vm-pgrange-states"
    dynamodb_table = "terraform-dev-vm-pgrange-state-lock"

    region = "us-east-1"
    key    = "terraform/dev-vm/pgrange"
    encrypt = true
  }
}
