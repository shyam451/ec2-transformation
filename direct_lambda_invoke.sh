#!/bin/bash
set -e

# Prompt for AWS credentials
echo "Please enter your AWS credentials:"
read -p "AWS Access Key ID: " AWS_ACCESS_KEY_ID
read -p "AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY
read -p "AWS Session Token (optional): " AWS_SESSION_TOKEN

# Export credentials
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_SESSION_TOKEN
export AWS_DEFAULT_REGION=us-east-1

echo "Finding the most recent Lambda function for ec2-transformation-asg-redeploy..."
LAMBDA_NAME=$(aws lambda list-functions --query "Functions[?starts_with(FunctionName, 'ec2-transformation-asg-redeploy')].FunctionName" --output text | tr '\t' '\n' | sort | tail -n 1)

if [ -z "$LAMBDA_NAME" ]; then
  echo "Error: No Lambda function found with name starting with 'ec2-transformation-asg-redeploy'"
  exit 1
fi

echo "Found Lambda function: $LAMBDA_NAME"

echo "Invoking Lambda function to trigger ASG redeploy..."
aws lambda invoke \
  --function-name "$LAMBDA_NAME" \
  --payload '{}' \
  response.json

echo "Lambda invocation response:"
cat response.json

echo "Waiting for logs to be available..."
sleep 10

LOG_GROUP_NAME="/aws/lambda/$LAMBDA_NAME"
echo "Fetching logs from $LOG_GROUP_NAME"

aws logs describe-log-streams \
  --log-group-name "$LOG_GROUP_NAME" \
  --order-by LastEventTime \
  --descending \
  --limit 1 > log_streams.json

LOG_STREAM=$(cat log_streams.json | jq -r '.logStreams[0].logStreamName')

if [ -n "$LOG_STREAM" ]; then
  echo "Fetching log events from stream: $LOG_STREAM"
  aws logs get-log-events \
    --log-group-name "$LOG_GROUP_NAME" \
    --log-stream-name "$LOG_STREAM" \
    --limit 20 > log_events.json
    
  echo "Lambda execution logs:"
  cat log_events.json | jq -r '.events[].message'
else
  echo "No log streams found for $LOG_GROUP_NAME"
fi

echo "Checking ASG instance refresh status..."
ASG_NAME=$(aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[?starts_with(AutoScalingGroupName, 'ec2-transformation-asg-')].AutoScalingGroupName" --output text | tr '\t' '\n' | sort | tail -n 1)
echo "Found ASG: $ASG_NAME"

aws autoscaling describe-instance-refreshes \
  --auto-scaling-group-name "$ASG_NAME" \
  --query "InstanceRefreshes[0]" \
  --output json > refresh_status.json
  
echo "Instance refresh status:"
cat refresh_status.json | jq
