################################################################################
# EC2
################################################################################

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = "${var.ec2_instance_type}"
  subnet_id                   = element(var.public_subnets, 0)
  key_name                    = aws_key_pair.keypair.id
  associate_public_ip_address = true

  root_block_device {
    volume_size = 8

  }


  vpc_security_group_ids = [aws_security_group.ssh.id]

    tags = merge(
    { "Name" = "${var.name}-bastion-server" },
    var.tags,
  )
}

################################################################################
# SECURITY GROUPS
################################################################################

resource "aws_security_group" "ssh" {
  description = "Giving ssh access"
  vpc_id      = "${var.vpc_id}"
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

################################################################################
# KEY PAIR
################################################################################

resource "tls_private_key" "private" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
# Create a "test_key" to AWS
resource "aws_key_pair" "keypair" {
  key_name   = "test_key"       # Create a "test_key" to AWS
  public_key = tls_private_key.private.public_key_openssh
}

resource "local_file" "ssh_key" {
  filename = "${aws_key_pair.keypair.key_name}.pem"
  content = tls_private_key.private.private_key_pem
  file_permission = "0400"
}