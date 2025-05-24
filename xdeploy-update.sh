#!/bin/bash
# xdeploy-update - Update xdeployer to the latest version
#
# This script updates xdeployer by downloading the latest version from GitHub
#
# Usage:
#   sh xdeploy-update.sh
#   or
#   sh xdeploy.sh update-xdeploy

set -e

echo "🔄 Updating xdeployer to the latest version..."
echo ""

# Check if we're in a directory with xdeploy.sh
if [ ! -f "xdeploy.sh" ]; then
    echo "❌ Error: xdeploy.sh not found in current directory"
    echo "Please run this script from the directory containing your xdeployer installation."
    exit 1
fi

# No backup needed - direct update

echo "⬇️  Downloading latest version from GitHub..."

# Download and extract the latest files
curl -L https://github.com/AmeerRizvi/xdeployer/archive/main.tar.gz | tar xz --strip=1 xdeployer-main/xdeploy.sh xdeployer-main/servers.json.template

# Make xdeploy.sh executable
chmod +x xdeploy.sh

echo ""
echo "✅ xdeployer has been updated successfully!"
echo ""
echo "Updated files:"
echo "  - xdeploy.sh (main deployment script)"
echo "  - servers.json.template (server configuration template)"
echo ""
echo "Note: Your existing servers.json configuration was preserved."
echo ""
echo "To see what's new, run: sh xdeploy.sh"
echo ""

exit 0
