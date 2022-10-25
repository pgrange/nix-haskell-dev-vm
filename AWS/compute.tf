resource "aws_instance" "haskell-dev-vm" {
  ami                  = data.aws_ami.haskell-dev-vm.id
  instance_type        = var.instance_type
  ebs_optimized        = true
  key_name             = var.instance_key_name

  root_block_device {
    encrypted             = true
    delete_on_termination = true
    volume_type           = "gp2"
    volume_size           = var.instance_volume_size
  }
  tags = {
    Name = "dev-vm-pgrange"
    OfficeHour = "true"
  }

  security_groups = [aws_security_group.haskell-dev-vm.name]
}

data "aws_ami" "haskell-dev-vm" {
  most_recent = true

  filter {
    name   = "name"
    values = ["iog-hydra-dev*"]
  }

  owners = ["949362844383"] # TODO get owner ID
}

output "dev-vm-ip" {
  description = "IP address to connect to the dev machine"
  value = aws_instance.haskell-dev-vm.public_ip
}

output "dev-vm-ssh-key" {
  description = "AWS managed ssh key to connect to the dev machine"
  value = aws_instance.haskell-dev-vm.key_name
}

output "dev-vm-ssh-user" {
  description = "ssh user to connect to the dev machine"
  value = data.aws_ami.haskell-dev-vm.tags["user"]
}
