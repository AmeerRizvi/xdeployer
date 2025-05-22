#!/bin/bash
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

setup_ssl() {
  local server_id=$1
  local server_info=$(jq -r ".servers[] | select(.id == \"$server_id\")" "$SERVERS_FILE")
  [ -z "$server_info" ] && echo "❌ Server '$server_id' not found." && exit 1

  local enabled=$(echo "$server_info" | jq -r '.enabled // true')
  [ "$enabled" = "false" ] && echo "⚠️ Skipping disabled server: $server_id" && return

  local key_path=$(echo "$server_info" | jq -r '.key_path')
  local user=$(echo "$server_info" | jq -r '.user')
  local host=$(echo "$server_info" | jq -r '.host')
  local domain=$(echo "$server_info" | jq -r '.domain // ""')

  [ -z "$domain" ] && echo "❌ No domain provided for server '$server_id'" && return

  echo "🔐 Setting up SSL for $domain on $host"

  ssh -i "$key_path" "$user@$host" bash -s -- "$domain" <<'ENDSSH'
    set -e
    DOMAIN="$1"

    echo "📦 Installing Certbot"
    if command -v dnf &>/dev/null; then
      sudo dnf install -y certbot python3-certbot-nginx
    elif command -v yum &>/dev/null; then
      sudo yum install -y certbot python3-certbot-nginx
    elif command -v apt-get &>/dev/null; then
      sudo apt-get update
      sudo apt-get install -y certbot python3-certbot-nginx
    fi

    echo "🔒 Requesting SSL cert for $DOMAIN"
    sudo certbot --nginx --non-interactive --agree-tos --email admin@$DOMAIN -d $DOMAIN -d www.$DOMAIN

    echo "🔁 Enabling auto-renew"
    sudo mkdir -p /etc/cron.d || { echo "❌ Failed to create cron.d dir"; exit 1; }
    echo "0 0 * * * root certbot renew --quiet" | sudo tee /etc/cron.d/certbot-renew >/dev/null || { echo "❌ Failed to write certbot cron job"; exit 1; }

    echo "✅ SSL setup complete for $DOMAIN"
ENDSSH
}

if [ "$TARGET" = "all" ]; then
  jq -r '.servers[] | select(.enabled != false) | .id' "$SERVERS_FILE" | while read -r id; do
    setup_ssl "$id"
  done
else
  setup_ssl "$TARGET"
fi
