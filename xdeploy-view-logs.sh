#!/bin/bash
# xdeploy-view-logs.sh - View PM2 logs for a Next.js application
#
# This script connects to a server and displays the PM2 logs for a specific application.
#
# Usage:
#   sh xdeploy-view-logs.sh [server_id] [lines]
#   - server_id: The ID of the server to view logs for
#   - lines: (Optional) Number of lines to show (default: 100)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVERS_FILE="$SCRIPT_DIR/servers.json"

if ! command -v jq &>/dev/null; then
  echo "❌ jq is required. Install it first."
  exit 1
fi

SERVER_ID=$1
LINES=${2:-100} # Default to 100 lines if not specified

if [ -z "$SERVER_ID" ]; then
  echo "❌ Please specify a server ID"
  echo "Usage: sh xdeploy-view-logs.sh [server_id] [lines]"
  echo "Available servers:"
  jq -r '.servers[] | "  - \(.id): \(.name) (\(.host)) [\(if .enabled == false then "DISABLED" else "ENABLED" end)]"' "$SERVERS_FILE"
  exit 1
fi

# Get server details
SERVER_INFO=$(jq -r ".servers[] | select(.id == \"$SERVER_ID\")" "$SERVERS_FILE")

if [ -z "$SERVER_INFO" ]; then
  echo "❌ Server with ID '$SERVER_ID' not found"
  echo "Available servers:"
  jq -r '.servers[] | "  - \(.id): \(.name) (\(.host)) [\(if .enabled == false then "DISABLED" else "ENABLED" end)]"' "$SERVERS_FILE"
  exit 1
fi

# Check if server is enabled
ENABLED=$(echo "$SERVER_INFO" | jq -r '.enabled // true')
if [ "$ENABLED" = "false" ]; then
  echo "⚠️ Warning: Server '$SERVER_ID' is disabled"
  echo "Continuing anyway..."
fi

# Extract server details
KEY_PATH=$(echo "$SERVER_INFO" | jq -r '.key_path')
USER=$(echo "$SERVER_INFO" | jq -r '.user')
HOST=$(echo "$SERVER_INFO" | jq -r '.host')
APP_NAME=$(echo "$SERVER_INFO" | jq -r '.app_name')

echo "📋 Viewing PM2 logs for $APP_NAME on $HOST (last $LINES lines)"
echo "Press Ctrl+C to exit"
echo ""

# Connect to the server and display PM2 logs
ssh -i "$KEY_PATH" "$USER@$HOST" "export NVM_DIR=\"\$HOME/.nvm\"; [ -s \"\$NVM_DIR/nvm.sh\" ] && source \"\$NVM_DIR/nvm.sh\"; pm2 logs $APP_NAME --lines $LINES"
