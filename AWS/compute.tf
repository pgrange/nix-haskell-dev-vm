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
