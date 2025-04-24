set -e

echo "Verifying final ASG configuration update..."

echo "Finding the most recent ASG for ec2-transformation..."
ASG_NAME=$(aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[?contains(AutoScalingGroupName, 'ec2-transformation')].AutoScalingGroupName" --output text | tr '\t' '\n' | sort | tail -n 1)
echo "Found ASG: $ASG_NAME"

echo "Checking ASG configuration..."
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-name $ASG_NAME \
  --query "{Name:AutoScalingGroupName,MinSize:MinSize,MaxSize:MaxSize,DesiredCapacity:DesiredCapacity}" \
  --output table

MIN_SIZE=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-name $ASG_NAME \
  --query "AutoScalingGroups[0].MinSize" \
  --output text)
  
MAX_SIZE=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-name $ASG_NAME \
  --query "AutoScalingGroups[0].MaxSize" \
  --output text)

DESIRED_CAPACITY=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-name $ASG_NAME \
  --query "AutoScalingGroups[0].DesiredCapacity" \
  --output text)

echo "Verification results:"
echo "--------------------"
echo "Current MinSize: $MIN_SIZE (Expected: 1)"
echo "Current MaxSize: $MAX_SIZE (Expected: 3)"
echo "Current DesiredCapacity: $DESIRED_CAPACITY"

if [ "$MIN_SIZE" -eq 1 ] && [ "$MAX_SIZE" -eq 3 ]; then
  echo "✅ ASG configuration successfully updated to min=1, max=3"
else
  echo "❌ ASG configuration update failed or not yet complete"
  echo "Current values: min=$MIN_SIZE, max=$MAX_SIZE"
  echo "Expected values: min=1, max=3"
fi

echo "Checking EC2 instances in ASG..."
aws ec2 describe-instances \
  --filters "Name=tag:aws:autoscaling:groupName,Values=$ASG_NAME" \
  --query "Reservations[*].Instances[*].{InstanceId:InstanceId,State:State.Name,LaunchTime:LaunchTime,Type:InstanceType}" \
  --output table

echo "Checking recent ASG activities..."
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name $ASG_NAME \
  --max-items 5 \
  --query "Activities[*].{ActivityId:ActivityId,Description:Description,Cause:Cause,StartTime:StartTime,EndTime:EndTime,StatusCode:StatusCode}" \
  --output table
