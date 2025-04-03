set -e

echo "Installing dependencies..."
npm install

echo "Creating deployment package..."
zip -r asg_redeploy.zip index.js node_modules

echo "Lambda package created successfully!"
