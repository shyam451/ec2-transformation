const AWS = require('aws-sdk');

exports.handler = async (event) => {
  const autoscaling = new AWS.AutoScaling();
  
  const asgName = process.env.ASG_NAME;
  
  if (!asgName) {
    console.error('ASG_NAME environment variable is not set');
    return {
      statusCode: 400,
      body: JSON.stringify({ message: 'ASG_NAME environment variable is not set' }),
    };
  }
  
  try {
    const checkParams = {
      AutoScalingGroupName: asgName,
    };
    
    console.log(`Checking for ongoing instance refreshes in ASG: ${asgName}`);
    const currentRefreshes = await autoscaling.describeInstanceRefreshes(checkParams).promise();
    
    if (currentRefreshes.InstanceRefreshes && currentRefreshes.InstanceRefreshes.length > 0) {
      for (const refresh of currentRefreshes.InstanceRefreshes) {
        if (['Pending', 'InProgress'].includes(refresh.Status)) {
          console.log(`Cancelling ongoing instance refresh: ${refresh.InstanceRefreshId}`);
          await autoscaling.cancelInstanceRefresh({
            AutoScalingGroupName: asgName
          }).promise();
        }
      }
    }
    
    const params = {
      AutoScalingGroupName: asgName,
      Strategy: 'Rolling',
      Preferences: {
        MinHealthyPercentage: 50,
        InstanceWarmup: 300,
        AutoRollback: true,
        ScaleInProtectedInstances: 'Terminate',
        StandbyInstances: 'Terminate'
      }
    };
    
    console.log(`Starting instance refresh for ASG: ${asgName}`);
    const result = await autoscaling.startInstanceRefresh(params).promise();
    
    console.log('Instance refresh started successfully:', result);
    return {
      statusCode: 200,
      body: JSON.stringify({ 
        message: 'Instance refresh started successfully',
        refreshId: result.InstanceRefreshId
      }),
    };
  } catch (error) {
    console.error('Error starting instance refresh:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ 
        message: 'Error starting instance refresh',
        error: error.message
      }),
    };
  }
};
