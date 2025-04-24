set -e

echo "Invoking Lambda function to refresh ASG and checking status..."

echo "Finding the most recent ASG for ec2-transformation..."
ASG_NAME=$(aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[?contains(AutoScalingGroupName, 'ec2-transformation')].AutoScalingGroupName" --output text | tr '\t' '\n' | sort | tail -n 1)
echo "Found ASG: $ASG_NAME"

echo "Checking ASG configuration before refresh..."
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-name $ASG_NAME \
  --query "{Name:AutoScalingGroupName,MinSize:MinSize,MaxSize:MaxSize,DesiredCapacity:DesiredCapacity}" \
  --output table

echo "Finding the most recent Lambda function for ec2-transformation-asg-redeploy..."
LAMBDA_NAME=$(aws lambda list-functions --query "Functions[?starts_with(FunctionName, 'ec2-transformation-asg-redeploy')].FunctionName" --output text | tr '\t' '\n' | sort | tail -n 1)
echo "Found Lambda function: $LAMBDA_NAME"

echo "Invoking Lambda function to trigger ASG redeploy..."
aws lambda invoke \
  --function-name $LAMBDA_NAME \
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
aws autoscaling describe-instance-refreshes \
  --auto-scaling-group-name "$ASG_NAME" \
  --query "InstanceRefreshes[0]" \
  --output json > refresh_status.json
  
echo "Instance refresh status:"
cat refresh_status.json | jq

echo "Waiting for instance refresh to complete..."
for i in {1..6}; do
  echo "Check $i of 6..."
  aws autoscaling describe-instance-refreshes \
    --auto-scaling-group-name "$ASG_NAME" \
    --query "InstanceRefreshes[0]" \
    --output json > refresh_status.json
    
  STATUS=$(cat refresh_status.json | jq -r '.Status')
  PERCENT=$(cat refresh_status.json | jq -r '.PercentageComplete')
  
  echo "Status: $STATUS, Percentage Complete: $PERCENT%"
  
  if [ "$STATUS" = "Successful" ] || [ "$STATUS" = "Cancelled" ] || [ "$STATUS" = "Failed" ]; then
    echo "Instance refresh completed with status: $STATUS"
    break
  fi
  
  echo "Waiting 30 seconds before next check..."
  sleep 30
done

echo "Verifying EC2 instances health after refresh..."
CURRENT_TIME=$(date +%s)

echo "EC2 instances after refresh:"
aws ec2 describe-instances \
  --filters "Name=tag:aws:autoscaling:groupName,Values=$ASG_NAME" \
  --query "Reservations[*].Instances[*].{InstanceId:InstanceId,State:State.Name,LaunchTime:LaunchTime,Type:InstanceType}" \
  --output table
  
echo "Checking for recently launched instances..."
INSTANCES=$(aws ec2 describe-instances \
  --filters "Name=tag:aws:autoscaling:groupName,Values=$ASG_NAME" \
  --query "Reservations[*].Instances[*].{InstanceId:InstanceId,LaunchTime:LaunchTime}" \
  --output json)
  
echo "$INSTANCES" > instances.json

RECENT_INSTANCES=$(cat instances.json | jq -r '.[][] | select(.LaunchTime != null) | .InstanceId + "," + .LaunchTime')

if [ -z "$RECENT_INSTANCES" ]; then
  echo "No instances found in the ASG"
  exit 1
fi

FOUND_RECENT=false

echo "Instance launch times:"
while IFS="," read -r INSTANCE_ID LAUNCH_TIME; do
  LAUNCH_SECONDS=$(date -d "$LAUNCH_TIME" +%s)
  
  TIME_DIFF=$(( (CURRENT_TIME - LAUNCH_SECONDS) / 60 ))
  
  echo "Instance $INSTANCE_ID launched $TIME_DIFF minutes ago"
  
  if [ $TIME_DIFF -le 10 ]; then
    echo "✅ Instance $INSTANCE_ID was launched recently ($TIME_DIFF minutes ago)"
    FOUND_RECENT=true
  fi
done <<< "$RECENT_INSTANCES"

if [ "$FOUND_RECENT" = true ]; then
  echo "✅ Health check passed: Found recently launched instances"
else
  echo "❌ Health check failed: No recently launched instances found"
  echo "This could be normal if the ASG determined no instances needed to be replaced"
  
  REFRESH_STATUS=$(cat refresh_status.json | jq -r '.Status')
  if [ "$REFRESH_STATUS" = "Successful" ]; then
    echo "✅ Instance refresh completed successfully, but no new instances were needed"
  else
    echo "❌ Instance refresh status: $REFRESH_STATUS"
  fi
fi

echo "Final ASG configuration:"
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-name $ASG_NAME \
  --query "{Name:AutoScalingGroupName,MinSize:MinSize,MaxSize:MaxSize,DesiredCapacity:DesiredCapacity}" \
  --output table

echo "ASG Refresh Summary:"
echo "-------------------"
echo "ASG Name: $ASG_NAME"
echo "Lambda Function: $LAMBDA_NAME"
echo "Refresh Status: $(cat refresh_status.json | jq -r '.Status')"
echo "Percentage Complete: $(cat refresh_status.json | jq -r '.PercentageComplete')%"
echo "Start Time: $(cat refresh_status.json | jq -r '.StartTime')"
echo "End Time: $(cat refresh_status.json | jq -r '.EndTime')"
echo "Recently Launched Instances: $FOUND_RECENT"
echo "-------------------"
