# Nginx and SSL Setup for xdeployer

This document explains how to use the `prepare-nginx` functionality in xdeployer to set up Nginx and SSL (Let's Encrypt) on your EC2 instances.

## Quick Start

```bash
# Download the prepare-nginx script
curl -L https://raw.githubusercontent.com/AmeerRizvi/xdeployer/main/prepare-nginx.sh -o prepare-nginx.sh

# Make it executable
chmod +x prepare-nginx.sh
```

If you've already installed xdeployer, the prepare-nginx script is included and can be used through the main xdeploy.sh script.

## Requirements

- SSH access to your EC2 instance(s)
- A properly configured `servers.json` file with your server details
- `jq` installed on your local machine (for JSON parsing)
- A valid domain name in the `domain` field of your server configuration (or in the `url` field as a fallback)

## Usage

You can use the prepare-nginx functionality in two ways: through the main xdeploy.sh script or by using the prepare-nginx.sh script directly.

### Using xdeploy.sh (recommended)

#### Prepare a specific EC2 instance with Nginx and SSL

```bash
sh xdeploy.sh prepare-nginx production
```

This will connect to the server with ID "production" and install/configure Nginx with SSL for the domain specified in your servers.json.

#### Prepare all EC2 instances with Nginx and SSL

```bash
sh xdeploy.sh prepare-nginx all
```

This will set up Nginx and SSL on all enabled servers defined in your `servers.json` file.

### Using prepare-nginx.sh directly

If you've downloaded only the prepare-nginx.sh script, you can use it directly:

```bash
# Prepare a specific EC2 instance
sh prepare-nginx.sh production

# Prepare all EC2 instances
sh prepare-nginx.sh all
```

Note: When using the script directly, make sure you have a valid `servers.json` file in the same directory.

## Server Configuration

For the prepare-nginx script to work properly, your server configuration in `servers.json` must include:

```json
{
  "servers": [
    {
      "id": "production",
      "name": "Production Server",
      "app_name": "my-nextjs-app",
      "port": 3000,
      "key_path": "~/.ssh/your-ec2-key.pem",
      "user": "ec2-user",
      "host": "ec2-xx-xx-xx-xx.compute.amazonaws.com",
      "remote_dir": "/home/ec2-user/apps/my-nextjs-app",
      "url": "http://your-domain-or-ip:3000/",
      "domain": "your-domain.com",
      "enabled": true
    }
  ]
}
```

The script will use the `domain` field for Nginx and SSL configuration. If the `domain` field is not provided, it will try to extract the domain from the `url` field as a fallback.

## What Gets Installed

### Nginx

The script installs Nginx using the appropriate package manager for your Linux distribution:

- For Ubuntu, Debian: Uses `apt-get`
- For Amazon Linux 2023, CentOS, RHEL: Uses `dnf`
- For older Amazon Linux, CentOS, RHEL: Uses `yum`

### Certbot (Let's Encrypt)

Certbot is installed to obtain and manage SSL certificates:

- For Ubuntu, Debian: Installs via apt-get
- For RHEL/CentOS/Amazon Linux: Creates a Python virtual environment and installs Certbot

### Firewall Configuration

The script attempts to configure the firewall to allow HTTP, HTTPS, and your application port:

- For systems using firewalld: Uses `firewall-cmd`
- For Ubuntu systems using ufw: Uses `ufw`

## Nginx Configuration

The script creates a basic Nginx configuration that:

1. Listens on port 80 (HTTP)
2. Sets up a reverse proxy to your Node.js application
3. Configures SSL with Certbot (which modifies the Nginx config to listen on port 443)

## SSL Certificate

The script obtains an SSL certificate for your domain and its www subdomain (e.g., example.com and www.example.com) using Let's Encrypt.

## Auto-Renewal

The script sets up a cron job to automatically renew your SSL certificates before they expire.

## Troubleshooting

### Domain Validation Issues

If you encounter issues with domain validation:

- Make sure your domain's DNS records point to your EC2 instance's IP address
- Ensure that port 80 is open to the internet for the Let's Encrypt validation process
- Check that your domain is correctly specified in the `url` field of your server configuration

### Permission Issues

If you encounter permission issues, make sure:

- Your SSH key has the correct permissions (typically `chmod 400 your-key.pem`)
- The user specified in `servers.json` has sudo privileges on the EC2 instance

### Connection Issues

If you can't connect to your EC2 instance:

- Verify the hostname/IP address in `servers.json`
- Check that your security groups allow SSH access (port 22)
- Ensure your SSH key path is correct

### Installation Failures

If software installation fails:

- Check the error message for specific issues
- Ensure your EC2 instance has internet access
- Try installing the software manually to identify any specific issues

## Next Steps

After setting up Nginx and SSL, you can:

1. Deploy your Next.js application using `sh xdeploy.sh create production`
2. Access your application securely via HTTPS
3. Customize your Nginx configuration for advanced features like caching, rate limiting, etc.
