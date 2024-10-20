variable "environment" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "public_cidrs" {
  type = list(string)
}

variable "private_cidrs" {
  type = list(string)
}

variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east1-b", "us-east-1c"]
}