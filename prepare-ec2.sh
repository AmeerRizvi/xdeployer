#!/bin/bash
# prepare-ec2.sh - EC2 Instance Preparation Script for xdeployer
#
# This script prepares an EC2 instance for running Next.js applications by installing:
# - Node.js and npm
# - PM2 process manager
# - Bun JavaScript runtime
#
# Usage:
#   sh prepare-ec2.sh [server_id|all]

set -e

# Script version
VERSION="1.0.0"

# Check if jq is installed
if ! command -v jq &>/dev/null; then
    echo "Error: jq is required but not installed."
    echo "Please install jq first:"
    echo "  - macOS: brew install jq"
    echo "  - Ubuntu/Debian: sudo apt-get install jq"
    echo "  - CentOS/RHEL: sudo yum install jq"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVERS_FILE="$SCRIPT_DIR/servers.json"

# Check if servers.json exists
if [ ! -f "$SERVERS_FILE" ]; then
    echo "Error: $SERVERS_FILE not found"
    exit 1
fi

# Function to list all available servers
list_servers() {
    echo "Available servers:"
    jq -r '.servers[] | "  - \(.id): \(.name) (\(.host)) [\(if .enabled == false then "DISABLED" else "ENABLED" end)]"' "$SERVERS_FILE"
}

# Function to prepare a specific EC2 server
prepare_ec2_server() {
    local server_id=$1

    # Get server details
    local server_info=$(jq -r ".servers[] | select(.id == \"$server_id\")" "$SERVERS_FILE")

    if [ -z "$server_info" ]; then
        echo "Error: Server with ID '$server_id' not found"
        list_servers
        exit 1
    fi

    # Check if server is enabled
    local enabled=$(echo "$server_info" | jq -r '.enabled // true')
    if [ "$enabled" = "false" ]; then
        echo "Skipping disabled server: $server_id"
        return
    fi

    # Extract server details
    local key_path=$(echo "$server_info" | jq -r '.key_path')
    local user=$(echo "$server_info" | jq -r '.user')
    local host=$(echo "$server_info" | jq -r '.host')
    local name=$(echo "$server_info" | jq -r '.name')

    echo "=== Preparing EC2 instance for $name ($host) ==="
    echo "This will install Node.js, npm, PM2, and Bun on the server."
    echo "Server: $host"
    echo "User: $user"

    # Execute remote commands to prepare the EC2 instance
    ssh -i "$key_path" "$user@$host" <<'EOF'
#!/bin/bash
set -e

echo "=== Preparing EC2 instance for Next.js deployment ==="

# Detect Linux distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VERSION=$VERSION_ID
elif type lsb_release >/dev/null 2>&1; then
    OS=$(lsb_release -si)
    VERSION=$(lsb_release -sr)
else
    OS=$(uname -s)
    VERSION=$(uname -r)
fi

echo "Detected OS: $OS $VERSION"

# Install Node.js and npm based on the OS
install_nodejs() {
    echo "Installing Node.js and npm..."

    if [[ "$OS" == *"Amazon Linux"* ]] || [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
        # Amazon Linux, CentOS, RHEL
        curl -fsSL https://rpm.nodesource.com/setup_22.x | sudo bash -
        sudo yum install -y nodejs
    elif [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
        # Ubuntu, Debian
        curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
        sudo apt-get install -y nodejs
    else
        echo "Unsupported OS for automatic Node.js installation."
        echo "Please install Node.js manually according to your OS."
        return 1
    fi

    # Verify installation
    node -v
    npm -v

    echo "Node.js and npm installed successfully."
    return 0
}

# Install PM2 globally
install_pm2() {
    echo "Installing PM2 globally..."
    sudo npm install -g pm2

    # Verify installation
    pm2 --version

    echo "PM2 installed successfully."
    return 0
}

# Install Bun
install_bun() {
    echo "Installing Bun..."
    curl -fsSL https://bun.sh/install | bash

    # Add Bun to PATH for the current session
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"

    # Verify installation
    bun --version

    echo "Bun installed successfully."
    return 0
}

# Main installation process
echo "Starting installation process..."

# Install Node.js and npm
if command -v node &>/dev/null && command -v npm &>/dev/null; then
    echo "Node.js and npm are already installed."
    node -v
    npm -v
else
    install_nodejs
fi

# Install PM2
if command -v pm2 &>/dev/null; then
    echo "PM2 is already installed."
    pm2 --version
else
    install_pm2
fi

# Install Bun
if command -v bun &>/dev/null; then
    echo "Bun is already installed."
    bun --version
else
    install_bun
fi

echo "=== EC2 instance preparation complete ==="
echo "Your EC2 instance is now ready for Next.js deployment with xdeployer."
EOF

    echo "=== EC2 preparation completed for $name ($host) ==="
    echo ""
}

# Main script logic
TARGET=$1

if [ -z "$TARGET" ]; then
    echo "Error: Please specify a server ID or 'all'"
    list_servers
    exit 1
fi

if [ "$TARGET" = "all" ]; then
    # Prepare all enabled servers
    server_ids=$(jq -r '.servers[] | select(.enabled != false) | .id' "$SERVERS_FILE")
    if [ -z "$server_ids" ]; then
        echo "No enabled servers found."
        exit 1
    fi
    for server_id in $server_ids; do
        prepare_ec2_server "$server_id"
    done
else
    # Prepare specific server
    prepare_ec2_server "$TARGET"
fi

exit 0
