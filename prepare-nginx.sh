#!/bin/bash
# prepare-nginx.sh - Nginx and SSL Setup Script for xdeployer
#
# This script sets up Nginx and SSL (Let's Encrypt) on an EC2 instance for Next.js applications
#
# Download and use this script:
# ```
# curl -L https://raw.githubusercontent.com/AmeerRizvi/xdeployer/main/prepare-nginx.sh -o prepare-nginx.sh
# chmod +x prepare-nginx.sh
# sh prepare-nginx.sh [server_id|all]
# ```

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

# Function to prepare Nginx on a specific EC2 server
prepare_nginx_server() {
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
    local port=$(echo "$server_info" | jq -r '.port')
    local domain=$(echo "$server_info" | jq -r '.domain // ""')
    local url=$(echo "$server_info" | jq -r '.url // ""')

    # If domain is not provided, try to extract it from URL
    if [ -z "$domain" ] && [ ! -z "$url" ]; then
        domain=$(echo "$url" | sed -E 's|^https?://||' | sed -E 's|/.*$||' | sed -E 's|:[0-9]+$||')
    fi

    if [ -z "$domain" ]; then
        echo "Error: No domain specified for server $server_id"
        echo "Please add a 'domain' field in servers.json for this server."
        return
    fi

    echo "=== Preparing Nginx and SSL for $name ($host) ==="
    echo "This will install and configure Nginx with SSL for your domain."
    echo "Server: $host"
    echo "User: $user"
    echo "Domain: $domain"
    echo "Port: $port"

    # Execute remote commands to prepare Nginx and SSL
    ssh -i "$key_path" "$user@$host" bash -c "$(
        cat <<'ENDSSH'
#!/bin/bash
set -e

# Get domain and port from arguments
DOMAIN="$1"
PORT="$2"

echo "=== Installing Nginx ==="
if command -v apt-get &>/dev/null; then
    # Debian/Ubuntu
    sudo apt-get update
    sudo apt-get install -y nginx
    sudo systemctl enable nginx
    sudo systemctl start nginx
elif command -v dnf &>/dev/null; then
    # Amazon Linux 2023/RHEL/CentOS
    sudo dnf install nginx -y
    sudo systemctl enable nginx
    sudo systemctl start nginx
elif command -v yum &>/dev/null; then
    # Older Amazon Linux/RHEL/CentOS
    sudo yum install nginx -y
    sudo systemctl enable nginx
    sudo systemctl start nginx
else
    echo "Unsupported OS. Please install Nginx manually."
    exit 1
fi

echo "=== Configuring Firewall Rules ==="
# Try different firewall commands, ignoring errors
if command -v firewall-cmd &>/dev/null; then
    # firewalld
    sudo firewall-cmd --add-service=http --permanent || true
    sudo firewall-cmd --add-service=https --permanent || true
    sudo firewall-cmd --add-port=${PORT}/tcp --permanent || true
    sudo firewall-cmd --reload || true
elif command -v ufw &>/dev/null; then
    # ufw (Ubuntu)
    sudo ufw allow 'Nginx Full' || true
    sudo ufw allow ${PORT}/tcp || true
fi

echo "=== Creating Nginx config for $DOMAIN ==="

sudo mkdir -p /etc/nginx/conf.d/

cat <<EOF | sudo tee /etc/nginx/conf.d/$DOMAIN.conf
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;

    location / {
        proxy_pass http://127.0.0.1:$PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

echo "=== Testing Nginx and Reloading ==="
sudo nginx -t && sudo systemctl reload nginx

echo "=== Installing Certbot (SSL tool) ==="
if command -v apt-get &>/dev/null; then
    # Debian/Ubuntu
    sudo apt-get install -y certbot python3-certbot-nginx
elif command -v dnf &>/dev/null || command -v yum &>/dev/null; then
    # RHEL/CentOS/Amazon Linux
    sudo dnf install -y augeas-libs || sudo yum install -y augeas-libs
    sudo python3 -m venv /opt/certbot/
    sudo /opt/certbot/bin/pip install --upgrade pip
    sudo /opt/certbot/bin/pip install certbot certbot-nginx
    sudo ln -sf /opt/certbot/bin/certbot /usr/bin/certbot
fi

echo "=== Obtaining SSL Certificate for $DOMAIN ==="
sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN || echo "SSL setup failed. You can run 'sudo certbot --nginx' manually later."

echo "=== Setting up Auto-Renewal ==="
echo "0 0,12 * * * root /usr/bin/certbot renew -q" | sudo tee -a /etc/crontab >/dev/null

echo "=== Done! HTTPS is enabled for $DOMAIN ==="
ENDSSH
    )" "$domain" "$port"

    echo "=== Nginx and SSL setup completed for $name ($host) ==="
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
        prepare_nginx_server "$server_id"
    done
else
    # Prepare specific server
    prepare_nginx_server "$TARGET"
fi

exit 0
