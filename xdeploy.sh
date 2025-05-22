#!/bin/bash
# xdeployer - Next.js EC2 Deployment Script with PM2
#
# A simple deployment script for Next.js applications to EC2 instances using PM2
#
# Usage:
#   Create a new deployment to all servers:
#     sh xdeploy.sh create all
#   Create a new deployment to a specific server:
#     sh xdeploy.sh create server1
#   Update an existing deployment to all servers:
#     sh xdeploy.sh update all
#   Update an existing deployment to a specific server:
#     sh xdeploy.sh update server1
#   List available servers:
#     sh xdeploy.sh list
#   Show server details:
#     sh xdeploy.sh info server1
#   Start dev server after update:
#     sh xdeploy.sh update server1 --dev
#   Prepare EC2 instance:
#     sh xdeploy.sh prepare-ec2 server1

set -e

# Script version
VERSION="1.0.0"

# GitHub repository information
GITHUB_REPO="AmeerRizvi/xdeployer"
GITHUB_BRANCH="main"
GITHUB_RAW_URL="https://raw.githubusercontent.com/$GITHUB_REPO/$GITHUB_BRANCH"

# Check if jq is installed
if ! command -v jq &>/dev/null; then
    echo "Error: jq is required but not installed."
    echo "Please install jq first:"
    echo "  - macOS: brew install jq"
    echo "  - Ubuntu/Debian: sudo apt-get install jq"
    echo "  - CentOS/RHEL: sudo yum install jq"
    exit 1
fi

# Check if curl is installed
if ! command -v curl &>/dev/null; then
    echo "Error: curl is required but not installed."
    echo "Please install curl first:"
    echo "  - macOS: brew install curl"
    echo "  - Ubuntu/Debian: sudo apt-get install curl"
    echo "  - CentOS/RHEL: sudo yum install curl"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVERS_FILE="$SCRIPT_DIR/servers.json"

# Check if servers.json exists
if [ ! -f "$SERVERS_FILE" ]; then
    echo "Error: $SERVERS_FILE not found"
    exit 1
fi

# Function to download a script if it doesn't exist
download_script() {
    local script_name=$1
    local script_path="$SCRIPT_DIR/$script_name"

    if [ ! -f "$script_path" ]; then
        echo "Script $script_name not found. Downloading from GitHub..."
        curl -s -L "$GITHUB_RAW_URL/$script_name" -o "$script_path"

        if [ $? -ne 0 ]; then
            echo "Error: Failed to download $script_name"
            exit 1
        fi

        chmod +x "$script_path"
        echo "Downloaded $script_name successfully."
    fi
}

# Function to get the script name with xdeploy prefix
get_script_name() {
    local base_name=$1
    echo "xdeploy-$base_name"
}

# Function to check if next.config.js or next.config.ts has standalone output configuration
check_standalone_config() {
    # Check for next.config.js or next.config.ts
    CONFIG_FILE=""
    if [ -f "next.config.js" ]; then
        CONFIG_FILE="next.config.js"
    elif [ -f "next.config.ts" ]; then
        CONFIG_FILE="next.config.ts"
    else
        echo "Error: No Next.js configuration file found"
        echo "xdeployer requires Next.js to be configured with standalone output."
        echo "Please create a next.config.js or next.config.ts file with 'output: \"standalone\"' configuration."
        exit 1
    fi

    # Check if the config file contains standalone output configuration
    if ! grep -q "output.*standalone" "$CONFIG_FILE"; then
        echo "Error: $CONFIG_FILE does not have standalone output configuration"
        echo "xdeployer requires Next.js to be configured with standalone output."
        echo "Please add the following to your $CONFIG_FILE:"
        echo ""
        echo "  output: 'standalone',"
        echo ""
        echo "Example:"
        echo "  /** @type {import('next').NextConfig} */"
        echo "  const nextConfig = {"
        echo "    output: 'standalone',"
        echo "    // other config options..."
        echo "  };"
        echo ""
        if [[ "$CONFIG_FILE" == "next.config.js" ]]; then
            echo "  module.exports = nextConfig;"
        else
            echo "  export default nextConfig;"
        fi
        exit 1
    fi

    echo "Found standalone output configuration in $CONFIG_FILE"
}

# Function to list all available servers
list_servers() {
    echo "Available servers:"
    jq -r '.servers[] | "  - \(.id): \(.name) (\(.url)) [\(if .enabled == false then "DISABLED" else "ENABLED" end)]"' "$SERVERS_FILE"
}

# Function to show server details
show_server_info() {
    local server_id=$1
    local server_info=$(jq -r ".servers[] | select(.id == \"$server_id\")" "$SERVERS_FILE")

    if [ -z "$server_info" ]; then
        echo "Error: Server with ID '$server_id' not found"
        list_servers
        exit 1
    fi

    echo "Server details for '$server_id':"
    echo "$server_info" | jq '.'
}

# Function to deploy to a specific server
deploy_to_server() {
    local mode=$1
    local server_id=$2

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
    local app_name=$(echo "$server_info" | jq -r '.app_name')
    local port=$(echo "$server_info" | jq -r '.port')
    local key_path=$(echo "$server_info" | jq -r '.key_path')
    local user=$(echo "$server_info" | jq -r '.user')
    local host=$(echo "$server_info" | jq -r '.host')
    local remote_dir=$(echo "$server_info" | jq -r '.remote_dir')
    local url=$(echo "$server_info" | jq -r '.url')
    local hostname=$(echo "$server_info" | jq -r '.hostname // ""')

    echo "=== Deploying to $server_id: $url ==="
    echo "Mode: $mode"
    echo "App: $app_name"
    echo "Host: $host"
    if [ ! -z "$hostname" ]; then
        echo "Hostname: $hostname"
    fi

    # Check if next.config.js has standalone output configuration
    check_standalone_config

    # Build the application if not already built
    if [ ! -d ".next/standalone" ]; then
        echo "Building application..."
        # Check if using npm, yarn, pnpm or bun
        if [ -f "package-lock.json" ]; then
            npm run build || exit 1
        elif [ -f "yarn.lock" ]; then
            yarn build || exit 1
        elif [ -f "pnpm-lock.yaml" ]; then
            pnpm run build || exit 1
        elif [ -f "bun.lockb" ]; then
            bun run build || exit 1
        else
            echo "No package manager lock file found. Defaulting to npm..."
            npm run build || exit 1
        fi
        cp -r public .next/standalone/ && cp -r .next/static .next/standalone/.next/
    fi

    # Create zip file if it doesn't exist
    if [ ! -f "standalone.zip" ]; then
        echo "Creating deployment package..."
        zip -r standalone.zip ./.next/standalone
    fi

    echo "Deploying to server..."
    # Create remote directory
    ssh -i "$key_path" "$user@$host" "mkdir -p $remote_dir"

    # Prepare the PM2 start command
    pm2_cmd="PORT=$port NODE_ENV=production"
    if [ ! -z "$hostname" ]; then
        pm2_cmd="HOSTNAME=$hostname $pm2_cmd"
    fi
    pm2_cmd="$pm2_cmd node .next/standalone/server.js"

    # Copy zip file
    scp -i "$key_path" standalone.zip "$user@$host:$remote_dir/"

    # Execute remote commands
    ssh -i "$key_path" "$user@$host" <<EOF
cd $remote_dir
echo "Extracting files..."
unzip -o standalone.zip -d . || exit 1
rm standalone.zip

# Load NVM if available
export NVM_DIR="\$HOME/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && source "\$NVM_DIR/nvm.sh"
[ -s "\$NVM_DIR/bash_completion" ] && source "\$NVM_DIR/bash_completion"

if [[ "$mode" == "create" ]]; then
  echo ">>> Starting new app with PM2..."
  pm2 delete "$app_name" || true
  pm2 start "$pm2_cmd" --name "$app_name"
else
  echo ">>> Updating app..."
  pm2 restart "$app_name"
fi
EOF

    echo "Deployment to $server_id complete!"
    echo "URL: $url"
    echo ""
}

# Main script logic
MODE=$1
TARGET=$2

if [ "$MODE" = "list" ]; then
    list_servers
    exit 0
fi

if [ "$MODE" = "info" ]; then
    if [ -z "$TARGET" ]; then
        echo "Error: Please specify a server ID"
        list_servers
        exit 1
    fi
    show_server_info "$TARGET"
    exit 0
fi

if [ "$MODE" = "version" ]; then
    echo "xdeployer version $VERSION"
    exit 0
fi

if [ "$MODE" = "setup-server" ] || [ "$MODE" = "prepare-ec2" ]; then
    if [ -z "$TARGET" ]; then
        echo "Error: Please specify a server ID or 'all'"
        list_servers
        exit 1
    fi

    # Get the script name with xdeploy prefix
    SCRIPT_NAME=$(get_script_name "setup-server.sh")

    # Download the script if it doesn't exist
    download_script "$SCRIPT_NAME"

    # Execute the script with the target server
    sh "$SCRIPT_DIR/$SCRIPT_NAME" "$TARGET"
    exit 0
fi

if [ "$MODE" = "setup-nginx" ] || [ "$MODE" = "prepare-nginx" ]; then
    if [ -z "$TARGET" ]; then
        echo "Error: Please specify a server ID or 'all'"
        list_servers
        exit 1
    fi

    # Get the script name with xdeploy prefix
    SCRIPT_NAME=$(get_script_name "setup-nginx.sh")

    # Download the script if it doesn't exist
    download_script "$SCRIPT_NAME"

    # Execute the script with the target server
    sh "$SCRIPT_DIR/$SCRIPT_NAME" "$TARGET"
    exit 0
fi

if [ "$MODE" = "setup-ssl" ] || [ "$MODE" = "prepare-nginx-ssl" ]; then
    if [ -z "$TARGET" ]; then
        echo "Error: Please specify a server ID or 'all'"
        list_servers
        exit 1
    fi

    # Get the script name with xdeploy prefix
    SCRIPT_NAME=$(get_script_name "setup-ssl.sh")

    # Download the script if it doesn't exist
    download_script "$SCRIPT_NAME"

    # Execute the script with the target server
    sh "$SCRIPT_DIR/$SCRIPT_NAME" "$TARGET"
    exit 0
fi

if [ "$MODE" = "update-nginx" ] || [ "$MODE" = "update-nginx-proxy" ]; then
    if [ -z "$TARGET" ]; then
        echo "Error: Please specify a server ID or 'all'"
        list_servers
        exit 1
    fi

    # Get the script name with xdeploy prefix
    SCRIPT_NAME=$(get_script_name "update-nginx.sh")

    # Download the script if it doesn't exist
    download_script "$SCRIPT_NAME"

    # Execute the script with the target server
    sh "$SCRIPT_DIR/$SCRIPT_NAME" "$TARGET"
    exit 0
fi

if [ "$MODE" = "add-domain" ] || [ "$MODE" = "add-nginx-domain" ]; then
    if [ -z "$TARGET" ]; then
        echo "Error: Please specify a server ID or 'all'"
        list_servers
        exit 1
    fi

    # Get the script name with xdeploy prefix
    SCRIPT_NAME=$(get_script_name "add-domain.sh")

    # Download the script if it doesn't exist
    download_script "$SCRIPT_NAME"

    # Execute the script with the target server
    sh "$SCRIPT_DIR/$SCRIPT_NAME" "$TARGET"
    exit 0
fi

if [ "$MODE" = "view-logs" ]; then
    if [ -z "$TARGET" ]; then
        echo "Error: Please specify a server ID"
        list_servers
        exit 1
    fi

    # Get the script name with xdeploy prefix
    SCRIPT_NAME=$(get_script_name "view-logs.sh")

    # Download the script if it doesn't exist
    download_script "$SCRIPT_NAME"

    # Execute the script with the target server and optional lines parameter
    sh "$SCRIPT_DIR/$SCRIPT_NAME" "$TARGET" "$3"
    exit 0
fi

if [[ "$MODE" != "create" && "$MODE" != "update" ]]; then
    echo "xdeployer version $VERSION"
    echo "Usage: $0 command [server_id|all] [options]"
    echo ""
    echo "Commands:"
    echo "  create [server_id|all]           - Create a new deployment"
    echo "  update [server_id|all]           - Update an existing deployment"
    echo "  list                             - List available servers"
    echo "  info [server_id]                 - Show server details"
    echo "  setup-server [server_id|all]      - Prepare EC2 instance with npm, pm2, and bun"
    echo "  setup-nginx [server_id|all]      - Setup Nginx as a reverse proxy"
    echo "  setup-ssl [server_id|all]         - Setup SSL certificates using Let's Encrypt"
    echo "  update-nginx [server_id|all]       - Update Nginx proxy configuration"
    echo "  add-domain [server_id|all]        - Add domain configuration to Nginx"
    echo "  view-logs [server_id] [lines]     - View PM2 logs for a specific server"
    echo "  version                          - Show version information"
    echo ""
    echo "Options:"
    echo "  --dev                            - Start development server after update (only with update command)"
    echo ""
    echo "Note: Missing scripts will be automatically downloaded from GitHub."
    echo ""
    list_servers
    exit 1
fi

if [ -z "$TARGET" ]; then
    echo "Error: Please specify a server ID or 'all'"
    list_servers
    exit 1
fi

# Check if next.config.js has standalone output configuration
check_standalone_config

# Build the application
echo "Building application..."
# Check if using npm, yarn, pnpm or bun
if [ -f "package-lock.json" ]; then
    npm run build || exit 1
elif [ -f "yarn.lock" ]; then
    yarn build || exit 1
elif [ -f "pnpm-lock.yaml" ]; then
    pnpm run build || exit 1
elif [ -f "bun.lockb" ]; then
    bun run build || exit 1
else
    echo "No package manager lock file found. Defaulting to npm..."
    npm run build || exit 1
fi
cp -r public .next/standalone/ && cp -r .next/static .next/standalone/.next/
zip -r standalone.zip ./.next/standalone

if [ "$TARGET" = "all" ]; then
    # Deploy to all enabled servers
    server_ids=$(jq -r '.servers[] | select(.enabled != false) | .id' "$SERVERS_FILE")
    if [ -z "$server_ids" ]; then
        echo "No enabled servers found."
        exit 1
    fi
    for server_id in $server_ids; do
        deploy_to_server "$MODE" "$server_id"
    done
else
    # Deploy to specific server
    deploy_to_server "$MODE" "$TARGET"
fi

# Clean up
rm standalone.zip

# Start dev server if in update mode and --dev flag is provided
if [[ "$MODE" == "update" && "$3" == "--dev" ]]; then
    echo "Starting development server..."
    # Check if using npm, yarn, pnpm or bun
    if [ -f "package-lock.json" ]; then
        npm run dev
    elif [ -f "yarn.lock" ]; then
        yarn dev
    elif [ -f "pnpm-lock.yaml" ]; then
        pnpm run dev
    elif [ -f "bun.lockb" ]; then
        bun dev
    else
        echo "No package manager lock file found. Defaulting to npm..."
        npm run dev
    fi
fi
