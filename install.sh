#!/bin/bash
# xdeployer installation script

echo "Installing xdeployer..."

# Check if we're in a Next.js project
if [ ! -f "package.json" ]; then
  echo "Error: No package.json found. Please run this script in a Next.js project directory."
  exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
  echo "Warning: jq is not installed. You will need to install it before using xdeployer."
  echo "  - macOS: brew install jq"
  echo "  - Ubuntu/Debian: sudo apt-get install jq"
  echo "  - CentOS/RHEL: sudo yum install jq"
fi

# Check if zip is installed
if ! command -v zip &> /dev/null; then
  echo "Warning: zip is not installed. You will need to install it before using xdeployer."
  echo "  - macOS: brew install zip"
  echo "  - Ubuntu/Debian: sudo apt-get install zip"
  echo "  - CentOS/RHEL: sudo yum install zip"
fi

# Copy the run.sh script
cp run.sh ../

# Copy the servers.json.template and rename it
cp servers.json.template ../servers.json

# Check if next.config.js exists and if it has the standalone output option
if [ -f "../next.config.js" ]; then
  if ! grep -q "output.*standalone" "../next.config.js"; then
    echo "Warning: Your next.config.js does not appear to have 'output: standalone' set."
    echo "This is required for xdeployer to work correctly."
    echo "Please add the following to your next.config.js:"
    echo ""
    echo "output: 'standalone',"
    echo ""
  fi
else
  echo "Warning: No next.config.js found. Creating one with standalone output..."
  cp next.config.js.template ../next.config.js
fi

echo ""
echo "xdeployer has been installed successfully!"
echo "Please edit the servers.json file to configure your deployment targets."
echo ""
echo "To deploy your Next.js app, run:"
echo "  sh run.sh create your-server-id"
echo ""
echo "For more information, see the README.md file."

exit 0
