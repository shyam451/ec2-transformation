
resource "null_resource" "cleanup_old_asgs" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<EOT
      echo "Cleaning up old Auto Scaling Groups..."
      
      CURRENT_ASG="${aws_autoscaling_group.asg.name}"
      echo "Current ASG: $CURRENT_ASG"
      
      OLD_ASGS=$(aws autoscaling describe-auto-scaling-groups \
        --region ${var.aws_region} \
        --query "AutoScalingGroups[?starts_with(AutoScalingGroupName, '${var.project_name}-asg-')].AutoScalingGroupName" \
        --output text)
      
      for ASG in $OLD_ASGS; do
        if [ "$ASG" != "$CURRENT_ASG" ]; then
          echo "Deleting old ASG: $ASG"
          
          aws autoscaling update-auto-scaling-group \
            --region ${var.aws_region} \
            --auto-scaling-group-name "$ASG" \
            --min-size 0 \
            --max-size 0 \
            --desired-capacity 0
          
          echo "Waiting for instances to terminate..."
          sleep 30
          
          aws autoscaling delete-auto-scaling-group \
            --region ${var.aws_region} \
            --auto-scaling-group-name "$ASG" \
            --force-delete
        fi
      done
      
      echo "Checking for orphaned EC2 instances (not part of any ASG)..."
      ORPHANED_INSTANCES=$(aws ec2 describe-instances \
        --region ${var.aws_region} \
        --filters "Name=tag:Name,Values=${var.project_name}-instance" "Name=instance-state-name,Values=running,pending,stopping,stopped" \
        --query "Reservations[].Instances[?!contains(Tags[*].Key, 'aws:autoscaling:groupName')].InstanceId" \
        --output text)
      
      if [ -n "$ORPHANED_INSTANCES" ]; then
        echo "Found orphaned instances (not part of any ASG): $ORPHANED_INSTANCES"
        echo "Terminating orphaned instances..."
        aws ec2 terminate-instances \
          --region ${var.aws_region} \
          --instance-ids $ORPHANED_INSTANCES
      else
        echo "No orphaned instances found."
      fi
      
      echo "Current ASG status:"
      aws autoscaling describe-auto-scaling-groups \
        --region ${var.aws_region} \
        --auto-scaling-group-name "$CURRENT_ASG" \
        --query "AutoScalingGroups[0].[AutoScalingGroupName,MinSize,MaxSize,DesiredCapacity,Instances[*].InstanceId]" \
        --output json
    EOT
  }

  depends_on = [
    aws_autoscaling_group.asg
  ]
}

output "cleanup_result" {
  description = "Result of cleanup operation"
  value       = "Cleanup of old ASGs and orphaned instances has been initiated. Check AWS console or logs for details."
  depends_on  = [null_resource.cleanup_old_asgs]
}
