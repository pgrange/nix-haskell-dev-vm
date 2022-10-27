variable instance_type {
  type = string
  default = "c5.2xlarge"
}
variable "instance_volume_size" {
  type = number
  default = 256
}
variable "instance_key_name" {
  type = string
  description = "The AWS managed ssh key authorized to connect to this machine"
}
