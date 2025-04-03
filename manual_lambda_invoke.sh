set -e


TEMP_DIR=$(mktemp -d)
echo "Created temporary directory: $TEMP_DIR"

cat > $TEMP_DIR/credentials.json << EOF
{
  "Version": 1,
  "AccessKeyId": "ENTER_YOUR_ACCESS_KEY_HERE",
  "SecretAccessKey": "ENTER_YOUR_SECRET_KEY_HERE"
}
EOF

echo "Please edit the credentials.json file with your AWS credentials"
echo "Then run the following commands:"
echo ""
echo "export AWS_SHARED_CREDENTIALS_FILE=$TEMP_DIR/credentials.json"
echo "export AWS_REGION=us-east-1"
echo ""
echo "# Find the Lambda function"
echo "LAMBDA_NAME=\$(aws lambda list-functions --query \"Functions[?starts_with(FunctionName, 'ec2-transformation-asg-redeploy')].FunctionName\" --output text | tr '\t' '\n' | sort | tail -n 1)"
echo "echo \"Found Lambda function: \$LAMBDA_NAME\""
echo ""
echo "# Invoke the Lambda function"
echo "aws lambda invoke --function-name \$LAMBDA_NAME --payload '{}' response.json"
echo "cat response.json"
echo ""
echo "# Get Lambda logs"
echo "sleep 10"
echo "LOG_GROUP_NAME=\"/aws/lambda/\$LAMBDA_NAME\""
echo "LOG_STREAM=\$(aws logs describe-log-streams --log-group-name \"\$LOG_GROUP_NAME\" --order-by LastEventTime --descending --limit 1 | jq -r '.logStreams[0].logStreamName')"
echo "aws logs get-log-events --log-group-name \"\$LOG_GROUP_NAME\" --log-stream-name \"\$LOG_STREAM\" --limit 20 | jq -r '.events[].message'"
echo ""
echo "# Check ASG instance refresh status"
echo "ASG_NAME=\$(aws autoscaling describe-auto-scaling-groups --query \"AutoScalingGroups[?starts_with(AutoScalingGroupName, 'ec2-transformation-asg-')].AutoScalingGroupName\" --output text | tr '\t' '\n' | sort | tail -n 1)"
echo "aws autoscaling describe-instance-refreshes --auto-scaling-group-name \"\$ASG_NAME\" --query \"InstanceRefreshes[0]\" --output json | jq"
echo ""
echo "# Clean up"
echo "rm -rf $TEMP_DIR"
