set -e

echo "Checking Lambda health status and ASG refresh..."

echo "Finding the most recent ASG for ec2-transformation..."
ASG_NAME=$(aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[?contains(AutoScalingGroupName, 'ec2-transformation')].AutoScalingGroupName" --output text | tr '\t' '\n' | sort | tail -n 1)
echo "Found ASG: $ASG_NAME"

echo "Checking ASG configuration..."
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-name $ASG_NAME \
  --query "{Name:AutoScalingGroupName,MinSize:MinSize,MaxSize:MaxSize,DesiredCapacity:DesiredCapacity}" \
  --output table

echo "Checking ASG instance refresh status..."
aws autoscaling describe-instance-refreshes \
  --auto-scaling-group-name "$ASG_NAME" \
  --query "InstanceRefreshes[0]" \
  --output json > refresh_status.json
  
echo "Instance refresh status:"
cat refresh_status.json | jq

CURRENT_TIME=$(date +%s)

echo "EC2 instances in ASG:"
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

echo "ASG Refresh Summary:"
echo "-------------------"
echo "ASG Name: $ASG_NAME"
REFRESH_STATUS=$(cat refresh_status.json | jq -r '.Status')
PERCENT_COMPLETE=$(cat refresh_status.json | jq -r '.PercentageComplete')
START_TIME=$(cat refresh_status.json | jq -r '.StartTime')
END_TIME=$(cat refresh_status.json | jq -r '.EndTime')

echo "Refresh Status: $REFRESH_STATUS"
echo "Percentage Complete: $PERCENT_COMPLETE%"
echo "Start Time: $START_TIME"
echo "End Time: $END_TIME"
echo "Recently Launched Instances: $FOUND_RECENT"
echo "-------------------"
