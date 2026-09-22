variable "name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "public_subnet_cidrs" {
  type = list(string)

  validation {
    condition     = length(var.public_subnet_cidrs) == 2
    error_message = "Exactly two public subnet CIDRs are required."
  }
}

variable "private_subnet_cidrs" {
  type = list(string)

  validation {
    condition     = length(var.private_subnet_cidrs) == 2
    error_message = "Exactly two private subnet CIDRs are required."
  }
}

variable "nat_gateway_count" {
  type    = number
  default = 1

  validation {
    condition     = var.nat_gateway_count >= 1 && var.nat_gateway_count <= 2
    error_message = "nat_gateway_count must be 1 or 2."
  }
}
