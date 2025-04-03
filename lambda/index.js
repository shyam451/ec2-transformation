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
    const params = {
      AutoScalingGroupName: asgName,
      Strategy: 'Rolling',
      Preferences: {
        MinHealthyPercentage: 50,
        InstanceWarmup: 300
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
