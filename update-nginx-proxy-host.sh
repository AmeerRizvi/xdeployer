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

update_proxy_host() {
    local server_id=$1
    local server_info=$(jq -r ".servers[] | select(.id == \"$server_id\")" "$SERVERS_FILE")
    [ -z "$server_info" ] && echo "❌ Server '$server_id' not found." && exit 1

    local enabled=$(echo "$server_info" | jq -r '.enabled // true')
    [ "$enabled" = "false" ] && echo "⚠️ Skipping disabled server: $server_id" && return

    local key_path=$(echo "$server_info" | jq -r '.key_path')
    local user=$(echo "$server_info" | jq -r '.user')
    local host=$(echo "$server_info" | jq -r '.host')
    local domain=$(echo "$server_info" | jq -r '.domain // ""')
    local hostname=$(echo "$server_info" | jq -r '.hostname // ""')
    local port=$(echo "$server_info" | jq -r '.port')

    [ -z "$domain" ] && echo "❌ No domain provided for server '$server_id'" && return
    [ -z "$hostname" ] && echo "❌ No hostname provided for server '$server_id'" && return
    [ -z "$port" ] && echo "❌ No port provided for server '$server_id'" && return

    echo "🔧 Ensuring proxy_pass points to $hostname:$port in $domain.conf on $host"

    ssh -i "$key_path" "$user@$host" bash -s -- "$domain" "$hostname" "$port" <<'ENDSSH'
    set -e
    DOMAIN="$1"
    HOSTNAME="$2"
    PORT="$3"
    CONF="/etc/nginx/conf.d/$DOMAIN.conf"

    if [ ! -f "$CONF" ]; then
      echo "❌ Config $CONF not found"
      exit 1
    fi

    MATCH_COUNT=$(grep -c "proxy_pass http://" "$CONF" || true)
    if [ "$MATCH_COUNT" -eq 0 ]; then
      echo "❌ No proxy_pass line found in $CONF"
      exit 1
    fi

    echo "🔁 Replacing proxy_pass with proxy_pass http://$HOSTNAME:$PORT"
    sudo sed -i "s|proxy_pass http://.*;|proxy_pass http://$HOSTNAME:$PORT;|g" "$CONF"
ENDSSH
}

if [ "$TARGET" = "all" ]; then
    jq -r '.servers[] | select(.enabled != false) | .id' "$SERVERS_FILE" | while read -r id; do
        update_proxy_host "$id"
    done
else
    update_proxy_host "$TARGET"
fi

echo "🔁 Reloading Nginx..."
ssh -i "$(jq -r ".servers[] | select(.id == \"$TARGET\") | .key_path" "$SERVERS_FILE")" \
    "$(jq -r ".servers[] | select(.id == \"$TARGET\") | .user" "$SERVERS_FILE")@$(jq -r ".servers[] | select(.id == \"$TARGET\") | .host" "$SERVERS_FILE")" \
    "sudo nginx -t && sudo systemctl reload nginx && echo '✅ Nginx reloaded on $TARGET'"
