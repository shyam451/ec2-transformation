set -e

echo "Verifying ASG configuration update..."

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

echo "Verification results:"
echo "--------------------"
echo "Current MinSize: $MIN_SIZE (Expected: 2)"
echo "Current MaxSize: $MAX_SIZE (Expected: 5)"

if [ "$MIN_SIZE" -eq 2 ] && [ "$MAX_SIZE" -eq 5 ]; then
  echo "✅ ASG configuration successfully updated to min=2, max=5"
else
  echo "❌ ASG configuration update failed or not yet complete"
  echo "Current values: min=$MIN_SIZE, max=$MAX_SIZE"
  echo "Expected values: min=2, max=5"
fi
