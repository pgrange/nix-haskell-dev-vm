resource "aws_security_group" "haskell-dev-vm" {
  name = "haskell-dev-vm"
  description = "Allow ssh to haskell-dev-vm"

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_eip" "haskell-dev-vm" {
  instance = aws_instance.haskell-dev-vm.id
}
