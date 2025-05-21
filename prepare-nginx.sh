#!/bin/bash

# This script sets up Nginx and SSL (Let's Encrypt) on an EC2 instance
#
# Download and use this script:
# ```
# curl -L https://raw.githubusercontent.com/AmeerRizvi/xdeployer/main/prepare-nginx.sh -o prepare-nginx.sh
# chmod +x prepare-nginx.sh
# sh prepare-nginx.sh your.domain.com 7586
# ```

DOMAIN=$1
PORT=$2

if [ -z "$DOMAIN" ] || [ -z "$PORT" ]; then
    echo "Usage: sh prepare-nginx-ssl.sh your.domain.com 7586"
    exit 1
fi

set -e

echo "=== Installing Nginx ==="
sudo dnf install nginx -y
sudo systemctl enable nginx
sudo systemctl start nginx

echo "=== Configuring Firewall Rules ==="
sudo firewall-cmd --add-service=http --permanent || true
sudo firewall-cmd --add-port=${PORT}/tcp --permanent || true
sudo firewall-cmd --reload || true

echo "=== Creating Nginx config for $DOMAIN ==="

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
sudo dnf install -y augeas-libs
sudo python3 -m venv /opt/certbot/
sudo /opt/certbot/bin/pip install --upgrade pip
sudo /opt/certbot/bin/pip install certbot certbot-nginx
sudo ln -sf /opt/certbot/bin/certbot /usr/bin/certbot

echo "=== Obtaining SSL Certificate for $DOMAIN ==="
sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN

echo "=== Setting up Auto-Renewal ==="
echo "0 0,12 * * * root /opt/certbot/bin/python -c 'import random; import time; time.sleep(random.random() * 3600)' && certbot renew -q" | sudo tee -a /etc/crontab >/dev/null

echo "=== Done! HTTPS is enabled for $DOMAIN ==="
