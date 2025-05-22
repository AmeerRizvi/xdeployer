#!/bin/bash
# add-nginx-domain.sh - Add a domain configuration to Nginx
#
# This script adds a domain configuration to Nginx without installing or preparing Nginx.
# It assumes Nginx is already installed and running on the server.
#
# Usage:
#   sh add-nginx-domain.sh [server_id|all]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVERS_FILE="$SCRIPT_DIR/servers.json"

if ! command -v jq &>/dev/null; then
  echo "❌ jq is required. Install it first."
  exit 1
fi

TARGET=$1
if [ -z "$TARGET" ]; then
  echo "❌ Please specify a server ID or 'all'"
  exit 1
fi

add_nginx_domain() {
  local server_id=$1
  local server_info=$(jq -r ".servers[] | select(.id == \"$server_id\")" "$SERVERS_FILE")
  [ -z "$server_info" ] && echo "❌ Server '$server_id' not found." && exit 1

  local enabled=$(echo "$server_info" | jq -r '.enabled // true')
  [ "$enabled" = "false" ] && echo "⚠️ Skipping disabled server: $server_id" && return

  local key_path=$(echo "$server_info" | jq -r '.key_path')
  local user=$(echo "$server_info" | jq -r '.user')
  local host=$(echo "$server_info" | jq -r '.host')
  local port=$(echo "$server_info" | jq -r '.port')
  local domain=$(echo "$server_info" | jq -r '.domain // ""')

  [ -z "$domain" ] && echo "❌ No domain provided for server '$server_id'" && return
  [ -z "$port" ] && echo "❌ No port provided for server '$server_id'" && return

  echo "🔧 Adding Nginx configuration for $domain on $host"

  ssh -i "$key_path" "$user@$host" bash -s -- "$domain" "$port" <<'ENDSSH'
    set -e
    DOMAIN="$1"
    PORT="$2"

    # Check if Nginx is installed
    if ! command -v nginx &>/dev/null; then
      echo "❌ Nginx is not installed on this server. Please install Nginx first."
      exit 1
    fi

    # Check if Nginx is running
    if ! systemctl is-active --quiet nginx; then
      echo "⚠️ Nginx is not running. Attempting to start..."
      sudo systemctl start nginx
      if ! systemctl is-active --quiet nginx; then
        echo "❌ Failed to start Nginx. Please check Nginx installation."
        exit 1
      fi
    fi

    # Create the configuration directory if it doesn't exist
    sudo mkdir -p /etc/nginx/conf.d/

    # Check if configuration already exists
    if [ -f "/etc/nginx/conf.d/$DOMAIN.conf" ]; then
      echo "⚠️ Configuration for $DOMAIN already exists. Overwriting..."
    fi

    # Create the configuration file
    cat <<EOF | sudo tee /etc/nginx/conf.d/$DOMAIN.conf >/dev/null
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

    # Test the configuration and reload Nginx
    if sudo nginx -t; then
      sudo systemctl reload nginx
      echo "✅ Nginx configuration added for $DOMAIN"
    else
      echo "❌ Nginx configuration test failed. Please check the configuration."
      exit 1
    fi
ENDSSH
}

if [ "$TARGET" = "all" ]; then
  jq -r '.servers[] | select(.enabled != false) | .id' "$SERVERS_FILE" | while read -r id; do
    add_nginx_domain "$id"
  done
else
  add_nginx_domain "$TARGET"
fi
