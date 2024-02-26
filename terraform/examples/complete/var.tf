variable "aws_region" {
  type    = string
  description = "The AWS region to deploy resources into"
}
variable "infra_name" {
  type = string
  description = "infra-name"
}
variable "vpc_cidr" {
  type    = string
  description = "CIDR block for the VPC"
}

variable "azs" {
  type    = list(string)
  description = "A list of availability zones in the region"
  default     = ["ap-northeast-2a", "ap-northeast-2b"]
}

variable "public_subnet_cidrs" {
  type    = list(string)
  description = "List of CIDR blocks for the public subnets"
}

variable "private_subnet_cidrs" {
  type    = list(string)
  description = "List of CIDR blocks for the private subnets"
}

variable "cluster_name" {
  type    = string
  description = "cluster-name"
}