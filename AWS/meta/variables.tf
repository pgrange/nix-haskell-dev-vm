variable "DYNAMODB_TABLE" {
  type = string
  default = "terraform-dev-vm-pgrange-state-lock"
}
variable "STATE_BUCKET" { 
  type = string 
  default = "terraform-dev-vm-pgrange-states"
}
