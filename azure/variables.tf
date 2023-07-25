variable "location" {
  description = "Location"
  default     = "eastus"
}

variable "vnet_name" {
  description = "Vnet name"
  default     = "test-vnet"
}

variable "address_space" {
  description = "Address space"
  type        = list(string)
  default     = ["10.0.0.0/0"]
}