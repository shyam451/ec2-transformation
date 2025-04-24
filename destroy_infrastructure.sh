set -e

echo "Initializing Terraform..."
rm -f backend.tf
terraform init

echo "Planning Terraform destroy..."
terraform plan -destroy -out=tfdestroyplan

echo "Applying Terraform destroy..."
terraform apply -auto-approve tfdestroyplan

echo "Verifying resources have been deleted..."
echo "Checking EC2 instances..."
aws ec2 describe-instances \
  --filters "Name=tag:Environment,Values=ec2-transformation" \
  --query "Reservations[*].Instances[*].{InstanceId:InstanceId,State:State.Name,Type:InstanceType,LaunchTime:LaunchTime,Name:Tags[?Key=='Name']|[0].Value}" \
  --output table
  
echo "Checking ASG status..."
aws autoscaling describe-auto-scaling-groups \
  --query "AutoScalingGroups[?contains(AutoScalingGroupName, 'ec2-transformation')].{Name:AutoScalingGroupName,MinSize:MinSize,MaxSize:MaxSize,DesiredCapacity:DesiredCapacity}" \
  --output table
  
echo "Checking Lambda functions..."
aws lambda list-functions \
  --query "Functions[?contains(FunctionName, 'ec2-transformation')].{Name:FunctionName,Runtime:Runtime,Memory:MemorySize}" \
  --output table
