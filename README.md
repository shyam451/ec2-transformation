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

## Configuration
- AWS Region: `us-east-1` (N. Virginia)
- EC2 Instance Type: `t2.micro` (Free tier eligible)
- Autoscaling Group: Min 1, Max 3, Desired 2 instances
- CloudWatch Alarms: CPU utilization-based scaling policies
- Security Group: Allows SSH (port 22) and HTTP (port 80) access

## Manual Deployment
1. Configure AWS CLI with appropriate credentials:
   ```
   aws configure
   ```
   
2. Initialize Terraform:
   ```
   terraform init
   ```
   
3. Plan the deployment:
   ```
   terraform plan
   ```
   
4. Apply the configuration:
   ```
   terraform apply
   ```

## CI/CD Pipeline
This repository includes a GitHub Actions workflow that:
1. Validates Terraform configuration
2. Plans changes on pull requests
3. Applies changes when merged to main branch

### Required GitHub Secrets
- `AWS_ACCESS_KEY_ID`: AWS access key with permissions to create resources
- `AWS_SECRET_ACCESS_KEY`: AWS secret key

### IAM Role Configuration
The GitHub Actions workflow is configured to assume the IAM role:
`arn:aws:iam::641002720432:role/ec2-role`

The workflow uses AWS OIDC provider for authentication with the following configuration:
- Provider URL: `https://token.actions.githubusercontent.com`
- Audience: `sts.amazonaws.com`
- Subject: `repo:shyam451/ec2-transformation:*`

### Current Implementation
- Lambda function implementation is currently commented out due to IAM permission constraints
- Resources are created with unique names to avoid conflicts with existing resources
- Autoscaling group is configured with CPU-based scaling policies
- EC2 instances run a simple web server that displays a welcome message

## Requirements
- Terraform >= 0.12
- AWS CLI configured with appropriate credentials
