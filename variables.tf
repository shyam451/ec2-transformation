variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "vpc_id" {
  description = "VPC ID where resources will be deployed (legacy - use new VPC instead)"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "List of subnet IDs for the autoscaling group (legacy - use new subnets instead)"
  type        = list(string)
  default     = null
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
  default     = null # Will be set dynamically if not provided
}

variable "key_name" {
  description = "SSH key name for EC2 instances"
  type        = string
  default     = null
}

variable "min_size" {
  description = "Minimum size of the autoscaling group"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum size of the autoscaling group"
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "Desired capacity of the autoscaling group"
  type        = number
  default     = 3
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "ec2-transformation"
}
# Terraform Plan Run: Thu Apr 24 01:48:27 UTC 2025
# Terraform Plan Run: Thu Apr 24 02:48:41 UTC 2025
