set -e

echo "Directly invoking Lambda function to refresh ASG and checking status..."

export AWS_REGION=us-east-1

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

echo "Checking ASG instance refresh status..."
aws autoscaling describe-instance-refreshes \
  --auto-scaling-group-name "$ASG_NAME" \
  --query "InstanceRefreshes[0]" \
  --output json > refresh_status.json
  
echo "Instance refresh status:"
cat refresh_status.json | jq

echo "ASG Refresh Summary:"
echo "-------------------"
echo "ASG Name: $ASG_NAME"
echo "Lambda Function: $LAMBDA_NAME"
REFRESH_STATUS=$(cat refresh_status.json | jq -r '.Status')
PERCENT_COMPLETE=$(cat refresh_status.json | jq -r '.PercentageComplete')
START_TIME=$(cat refresh_status.json | jq -r '.StartTime')
END_TIME=$(cat refresh_status.json | jq -r '.EndTime')

echo "Refresh Status: $REFRESH_STATUS"
echo "Percentage Complete: $PERCENT_COMPLETE%"
echo "Start Time: $START_TIME"
echo "End Time: $END_TIME"
echo "-------------------"

echo "EC2 instances in ASG:"
aws ec2 describe-instances \
  --filters "Name=tag:aws:autoscaling:groupName,Values=$ASG_NAME" \
  --query "Reservations[*].Instances[*].{InstanceId:InstanceId,State:State.Name,LaunchTime:LaunchTime,Type:InstanceType}" \
  --output table
