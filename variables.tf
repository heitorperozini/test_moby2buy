variable "name" {
  description = "Name"
  default     = ""
}

variable "region" {
  description = "AWS Region"
  default     = ""
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  default     = ""
}

variable "public_subnets" {
  description = "Public CIDR."
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  description = "Private CIDR"
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "s3_bucket_name" {
  description = "S3 Bucket name."
  default     = ""
}

variable "ec2_instance_type" {
  description = "EC2 Instance Type."
  default     = ""
}

variable "key_pair" {
  description = "Key Pair ID."
  default     = ""
}
