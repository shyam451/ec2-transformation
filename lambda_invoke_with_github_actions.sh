#!/bin/bash
set -e

# Create a temporary commit to trigger GitHub Actions
echo "Creating a temporary commit to trigger GitHub Actions workflow..."
echo "# Trigger Lambda invocation - $(date)" > trigger_lambda.md
git add trigger_lambda.md
git commit -m "Trigger Lambda invocation via GitHub Actions"
git push origin devin/1743646842-ec2-asg-lambda

echo "Commit pushed to GitHub. This will trigger the Terraform CI/CD workflow."
echo "The workflow will automatically invoke the Lambda function."
echo "Check the GitHub Actions logs for the Lambda invocation results."
