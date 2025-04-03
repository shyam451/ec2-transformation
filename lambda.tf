
resource "aws_lambda_function" "asg_redeploy" {
  function_name    = "${var.project_name}-asg-redeploy-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  filename         = "${path.module}/lambda/asg_redeploy.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda/asg_redeploy.zip")
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  timeout          = 30
  memory_size      = 128

  environment {
    variables = {
      ASG_NAME = aws_autoscaling_group.asg.name
    }
  }

  tags = {
    Name        = "${var.project_name}-asg-redeploy"
    Environment = var.environment
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_policy_attachment
  ]
}

resource "aws_cloudwatch_event_rule" "scheduled_redeploy" {
  name                = "${var.project_name}-scheduled-redeploy-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  description         = "Trigger ASG redeploy on a schedule"
  schedule_expression = "rate(7 days)"
  is_enabled          = false # Disabled by default, enable if needed

  tags = {
    Name        = "${var.project_name}-scheduled-redeploy"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.scheduled_redeploy.name
  target_id = "TriggerLambda"
  arn       = aws_lambda_function.asg_redeploy.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.asg_redeploy.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.scheduled_redeploy.arn
}
