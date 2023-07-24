output "public_ip" {
  value = aws_instance.bastion.public_ip
}

output "keypair" {
  value = aws_key_pair.keypair.id
}

output "bastion_sg" {
  value = aws_security_group.ssh.id
}
