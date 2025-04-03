variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "VPC ID where resources will be deployed"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "List of subnet IDs for the autoscaling group"
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
  default     = 2
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
