variable "name" {
  description = "Name"
}

variable "ec2_instance_type" {
  description = "EC2 Instance Type."
  default     = ""
}

variable "vpc_id" {
  description = "VPC id"
}

variable "public_subnets" {
  description = "Public Cidr"
}

variable "private_subnets" {
  description = "Public Cidr"
}

variable "bucket_arn" {
  description = "Bucket ARN"
}

variable "bastion_sg" {
  description = "Bastion Security Group"
  default     = ""
}

variable "key_pair" {
  description = "Key pair name"
  default     = ""
}

variable "tags" {
  description = "General Tags"
}