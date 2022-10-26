output "dev-vm-ip" {
  description = "IP address to connect to the dev machine"
  value = aws_eip.haskell-dev-vm.public_ip
}

output "dev-vm-ssh-key" {
  description = "AWS managed ssh key to connect to the dev machine"
  value = aws_instance.haskell-dev-vm.key_name
}

output "dev-vm-ssh-user" {
  description = "ssh user to connect to the dev machine"
  value = data.aws_ami.haskell-dev-vm.tags["user"]
}
