
resource "null_resource" "invoke_lambda" {
  depends_on = [aws_lambda_function.asg_redeploy]

  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<EOT
      echo "Invoking Lambda function to trigger ASG redeploy..."
      aws lambda invoke \
        --function-name ${aws_lambda_function.asg_redeploy.function_name} \
        --region ${var.aws_region} \
        --payload '{}' \
        /tmp/lambda_output.json
      cat /tmp/lambda_output.json
    EOT
  }
}

output "lambda_invocation_result" {
  description = "Result of Lambda invocation (check logs for details)"
  value       = "Lambda function ${aws_lambda_function.asg_redeploy.function_name} has been invoked. Check CloudWatch logs for details."
  depends_on  = [null_resource.invoke_lambda]
}
