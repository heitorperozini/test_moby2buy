variable "name" {
  description = "Name"
}

variable "vpc_cidr" {
  description = "VPC Cidr"
}

variable "public_subnets" {
  description = "Public Cidr"
}

variable "private_subnets" {
  description = "Private Cidr"
}

variable "tags" {
  description = "General tags"
}
variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}