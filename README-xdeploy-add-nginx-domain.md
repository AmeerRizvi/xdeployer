# Add Nginx Domain Configuration

This document explains how to use the `add-nginx-domain.sh` script to add a domain configuration to Nginx for your Next.js applications.

## Quick Start

```bash
# Download the script
curl -L https://raw.githubusercontent.com/AmeerRizvi/xdeployer/main/add-nginx-domain.sh -o add-nginx-domain.sh
chmod +x add-nginx-domain.sh

# Run the script
sh add-nginx-domain.sh production
```

## What It Does

The script:

1. Connects to your EC2 instance via SSH
2. Checks if Nginx is installed and running
3. Creates a domain configuration file in `/etc/nginx/conf.d/`
4. Sets up a reverse proxy to your Next.js application
5. Tests the configuration and reloads Nginx

Unlike the `prepare-nginx.sh` script, this script does not install Nginx. It assumes Nginx is already installed and running on your server.

## Requirements

- SSH access to your EC2 instance(s)
- A properly configured `servers.json` file
- `jq` installed on your local machine
- Nginx already installed and running on your EC2 instance

## Usage

```bash
# Add Nginx domain configuration for a specific server
sh add-nginx-domain.sh production

# Add Nginx domain configuration for all enabled servers
sh add-nginx-domain.sh all
```

## Server Configuration

Your `servers.json` file must include:

```json
{
  "servers": [
    {
      "id": "production",
      "key_path": "~/.ssh/your-ec2-key.pem",
      "user": "ec2-user",
      "host": "ec2-xx-xx-xx-xx.compute.amazonaws.com",
      "domain": "your-domain.com",
      "port": 3000,
      "hostname": "172.31.14.83",
      "enabled": true
    }
  ]
}
```

The script requires the following fields:

- `domain`: The domain name for the Nginx configuration
- `port`: The port your application is running on
- `hostname`: The hostname or IP address to proxy to (defaults to "127.0.0.1" if not provided)

## How It Works

1. The script connects to your EC2 instance via SSH
2. It checks if Nginx is installed and running
3. It creates a configuration file at `/etc/nginx/conf.d/your-domain.com.conf`
4. The configuration sets up a reverse proxy from your domain to your application port
5. It tests the configuration and reloads Nginx to apply the changes

## Nginx Configuration

The script creates a basic Nginx configuration that:

```nginx
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;

    location / {
        proxy_pass http://172.31.14.83:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

## Troubleshooting

### Nginx Not Installed

If Nginx is not installed on your server, the script will fail with an error message. You should run `prepare-nginx.sh` first to install Nginx.

### Nginx Not Running

If Nginx is installed but not running, the script will attempt to start it. If it fails to start, you should check your Nginx installation.

### Configuration Test Failed

If the Nginx configuration test fails, the script will not reload Nginx. You should check the error message and fix the configuration manually.

### Permission Issues

If you encounter permission issues:

- Check SSH key permissions (`chmod 400 your-key.pem`)
- Ensure the user has sudo privileges on the EC2 instance

### Connection Issues

If you can't connect to your EC2 instance:

- Verify the hostname/IP address in `servers.json`
- Check that your security groups allow SSH access (port 22)
- Ensure your SSH key path is correct

## Next Steps

After adding the Nginx domain configuration, you can:

1. Set up SSL certificates using `prepare-nginx-ssl.sh`
2. Deploy your Next.js application using `xdeploy.sh create production`
3. Access your application via your domain name
