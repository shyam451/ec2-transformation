output "autoscaling_group_name" {
  description = "Name of the autoscaling group"
  value       = aws_autoscaling_group.asg.name
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.asg_launch_template.id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.instance_sg.id
}

/*
output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.asg_redeploy.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.asg_redeploy.arn
}
*/
