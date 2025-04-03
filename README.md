# EC2 Transformation with Terraform

This repository contains Terraform code to:
1. Deploy EC2 instances under an autoscaling group (using free tier eligible instances)
2. Create a Lambda function that can trigger a redeploy using the autoscaling group

## Structure
- `main.tf` - Main Terraform configuration
- `variables.tf` - Variable definitions
- `outputs.tf` - Output definitions
- `lambda.tf` - Lambda function configuration
- `asg.tf` - Autoscaling group configuration
- `lambda/` - Directory containing Lambda function code
- `.github/workflows/` - GitHub Actions workflow for CI/CD

## Usage
1. Initialize Terraform: `terraform init`
2. Plan the deployment: `terraform plan`
3. Apply the configuration: `terraform apply`

## CI/CD Pipeline
This repository includes a GitHub Actions workflow that:
1. Validates Terraform configuration
2. Plans changes on pull requests
3. Applies changes when merged to main branch

### Required GitHub Secrets
- `AWS_ACCESS_KEY_ID`: AWS access key with permissions to create resources
- `AWS_SECRET_ACCESS_KEY`: AWS secret key
- `AWS_REGION`: (Optional) AWS region to deploy resources (defaults to us-east-1)

## Requirements
- Terraform >= 0.12
- AWS CLI configured with appropriate credentials
