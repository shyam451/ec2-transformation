#!/bin/bash
set -e

# Open GitHub Actions workflow in browser to trigger manually
echo "Please follow these steps to trigger the Lambda function:"
echo "1. Go to your GitHub repository: https://github.com/shyam451/ec2-transformation"
echo "2. Click on 'Actions' tab"
echo "3. Select 'Direct Lambda Invocation' workflow from the left sidebar"
echo "4. Click 'Run workflow' button"
echo "5. Click 'Run workflow' in the dropdown"
echo "6. Wait for the workflow to complete and check the logs"
echo ""
echo "Alternatively, you can use the AWS Management Console to invoke the Lambda function:"
echo "1. Go to AWS Lambda console"
echo "2. Find the function named 'ec2-transformation-asg-redeploy-*'"
echo "3. Click 'Test' button"
echo "4. Use empty JSON payload '{}'"
echo "5. Click 'Test' to invoke the function"
echo ""
echo "This will trigger an instance refresh in your Auto Scaling Group."
