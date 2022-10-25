resource "aws_security_group_rule" "ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.haskell-dev-vm.id
}

resource "aws_security_group_rule" "mosh" {
  type              = "ingress"
  from_port         = 60000
  to_port           = 61000
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.haskell-dev-vm.id
}

resource "aws_security_group_rule" "out" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.haskell-dev-vm.id
}

resource "aws_security_group" "haskell-dev-vm" {
  name = "haskell-dev-vm"
  description = "Allow ssh to haskell-dev-vm"
}

resource "aws_eip" "haskell-dev-vm" {
  instance = aws_instance.haskell-dev-vm.id
}
