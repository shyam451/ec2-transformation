#!/bin/bash
set -e

TIMESTAMP=$(date +%s)
echo "Timestamp: $TIMESTAMP"

echo "Creating Lambda invocation workflow file..."

cat > .github/workflows/trigger_lambda_now.yml << 'EOF'
name: Trigger Lambda Now

on:
  push:
    paths:
      - 'direct_lambda_invoke.sh'

permissions:
  contents: read
  id-token: write

jobs:
  invoke_lambda:
    name: Invoke Lambda and Check ASG
    runs-on: ubuntu-latest
    
    steps:
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        role-to-assume: arn:aws:iam::641002720432:role/ec2-role
        aws-region: us-east-1
        
    - name: Check ASG Before Lambda
      run: |
        echo "Checking ASG status before Lambda invocation..."
        ASG_NAME=$(aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[?starts_with(AutoScalingGroupName, 'ec2-transformation-asg-')].AutoScalingGroupName" --output text | tr '\t' '\n' | sort | tail -n 1)
        echo "Found ASG: $ASG_NAME"
        
        echo "ASG Configuration:"
        aws autoscaling describe-auto-scaling-groups \
          --auto-scaling-group-name "$ASG_NAME" \
          --query "AutoScalingGroups[0].{Name:AutoScalingGroupName,MinSize:MinSize,MaxSize:MaxSize,DesiredCapacity:DesiredCapacity}" \
          --output table
          
        echo "ASG Instances:"
        aws autoscaling describe-auto-scaling-groups \
          --auto-scaling-group-name "$ASG_NAME" \
          --query "AutoScalingGroups[0].Instances[*].{InstanceId:InstanceId,LifecycleState:LifecycleState,HealthStatus:HealthStatus,AvailabilityZone:AvailabilityZone}" \
          --output table
        
    - name: Find Lambda Function
      id: find_lambda
      run: |
        echo "Finding the most recent Lambda function for ec2-transformation-asg-redeploy..."
        LAMBDA_NAME=$(aws lambda list-functions --query "Functions[?starts_with(FunctionName, 'ec2-transformation-asg-redeploy')].FunctionName" --output text | tr '\t' '\n' | sort | tail -n 1)
        echo "Found Lambda function: $LAMBDA_NAME"
        echo "LAMBDA_NAME=$LAMBDA_NAME" >> $GITHUB_ENV
        
    - name: Invoke Lambda Function
      run: |
        echo "Invoking Lambda function to trigger ASG redeploy..."
        aws lambda invoke \
          --function-name ${{ env.LAMBDA_NAME }} \
          --payload '{}' \
          response.json
        
        echo "Lambda invocation response:"
        cat response.json
        
    - name: Get Lambda Logs
      run: |
        echo "Waiting for logs to be available..."
        sleep 10
        LOG_GROUP_NAME="/aws/lambda/${{ env.LAMBDA_NAME }}"
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
        
    - name: Wait for Instance Refresh
      run: |
        echo "Waiting for instance refresh to start..."
        sleep 30
        
    - name: Check ASG After Lambda
      run: |
        echo "Checking ASG status after Lambda invocation..."
        ASG_NAME=$(aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[?starts_with(AutoScalingGroupName, 'ec2-transformation-asg-')].AutoScalingGroupName" --output text | tr '\t' '\n' | sort | tail -n 1)
        echo "Found ASG: $ASG_NAME"
        
        echo "ASG Configuration:"
        aws autoscaling describe-auto-scaling-groups \
          --auto-scaling-group-name "$ASG_NAME" \
          --query "AutoScalingGroups[0].{Name:AutoScalingGroupName,MinSize:MinSize,MaxSize:MaxSize,DesiredCapacity:DesiredCapacity}" \
          --output table
          
        echo "ASG Instances:"
        aws autoscaling describe-auto-scaling-groups \
          --auto-scaling-group-name "$ASG_NAME" \
          --query "AutoScalingGroups[0].Instances[*].{InstanceId:InstanceId,LifecycleState:LifecycleState,HealthStatus:HealthStatus,AvailabilityZone:AvailabilityZone}" \
          --output table
          
        echo "Instance Refresh Status:"
        aws autoscaling describe-instance-refreshes \
          --auto-scaling-group-name "$ASG_NAME" \
          --query "InstanceRefreshes[*].{RefreshId:InstanceRefreshId,Status:Status,StartTime:StartTime,PercentageComplete:PercentageComplete}" \
          --output table
EOF

echo "Workflow file created. Commit and push this file to trigger the Lambda invocation."
echo "Run: git add .github/workflows/trigger_lambda_now.yml direct_lambda_invoke.sh && git commit -m 'Retrigger Lambda function - $TIMESTAMP' && git push origin devin/1743646842-ec2-asg-lambda"
