#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVERS_FILE="$SCRIPT_DIR/servers.json"

if ! command -v jq &>/dev/null; then
  echo "❌ jq is required. Install it first."; exit 1
fi

TARGET=$1
if [ -z "$TARGET" ]; then
  echo "❌ Please specify a server ID or 'all'"; exit 1
fi

prepare_nginx_server() {
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

  echo "🚀 Setting up Nginx on $host for $domain"

  ssh -i "$key_path" "$user@$host" bash -s -- "$domain" "$port" <<'ENDSSH'
    set -e
    DOMAIN="$1"
    PORT="$2"

    if command -v dnf &>/dev/null; then
      sudo dnf install -y nginx
    elif command -v yum &>/dev/null; then
      sudo yum install -y nginx
    elif command -v apt-get &>/dev/null; then
      sudo apt-get update
      sudo apt-get install -y nginx
    fi

    sudo systemctl enable nginx
    sudo systemctl start nginx

    sudo mkdir -p /etc/nginx/conf.d/
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

    sudo nginx -t && sudo systemctl reload nginx
    echo "✅ Nginx setup complete for $DOMAIN"
ENDSSH
}

if [ "$TARGET" = "all" ]; then
  jq -r '.servers[] | select(.enabled != false) | .id' "$SERVERS_FILE" | while read -r id; do
    prepare_nginx_server "$id"
  done
else
  prepare_nginx_server "$TARGET"
fi
