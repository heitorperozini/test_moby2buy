variable "location" {
  description = "Location"
  default     = "us-east-1"
}

variable "vnet_name" {
  description = "Vnet name"
  default     = "test-vnet"
}

variable "address_space" {
  description = "Address space"
  default     = "10.0.0.0/0"
}