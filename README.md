# EC2 Transformation with Terraform

This repository contains Terraform code to:
1. Deploy EC2 instances under an autoscaling group
2. Create a Lambda function that can trigger a redeploy using the autoscaling group

## Structure
- `main.tf` - Main Terraform configuration
- `variables.tf` - Variable definitions
- `outputs.tf` - Output definitions
- `lambda.tf` - Lambda function configuration
- `asg.tf` - Autoscaling group configuration
- `lambda/` - Directory containing Lambda function code

## Usage
1. Initialize Terraform: `terraform init`
2. Plan the deployment: `terraform plan`
3. Apply the configuration: `terraform apply`

## Requirements
- Terraform >= 0.12
- AWS CLI configured with appropriate credentials
