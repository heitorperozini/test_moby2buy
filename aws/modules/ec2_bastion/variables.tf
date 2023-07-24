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

variable "tags" {
  description = "General tags"
}