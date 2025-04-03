set -e

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
