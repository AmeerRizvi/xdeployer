# Nginx and SSL Setup for xdeployer

This document explains how to use the Nginx setup scripts in xdeployer to configure reverse proxy and SSL for your Next.js applications.

## Available Scripts

| Script                         | Description                                     |
| ------------------------------ | ----------------------------------------------- |
| **prepare-nginx.sh**           | Sets up Nginx as a reverse proxy                |
| **prepare-nginx-ssl.sh**       | Configures SSL certificates using Let's Encrypt |
| **update-nginx-proxy-host.sh** | Updates Nginx proxy configuration               |

## Quick Start

```bash
# Download the scripts
curl -L https://raw.githubusercontent.com/AmeerRizvi/xdeployer/main/prepare-nginx.sh -o prepare-nginx.sh
curl -L https://raw.githubusercontent.com/AmeerRizvi/xdeployer/main/prepare-nginx-ssl.sh -o prepare-nginx-ssl.sh

# Make them executable
chmod +x prepare-nginx.sh prepare-nginx-ssl.sh

# Or use through xdeploy.sh if you've installed the full package
sh xdeploy.sh prepare-nginx production
```

## Requirements

- SSH access to your EC2 instance(s)
- A properly configured `servers.json` file
- `jq` installed on your local machine
- A valid domain name in the `domain` field of your server configuration

## Usage

### Set up Nginx

```bash
# Using xdeploy.sh
sh xdeploy.sh prepare-nginx production

# Or directly
sh prepare-nginx.sh production
```

### Set up SSL with Let's Encrypt

```bash
# Using xdeploy.sh
sh xdeploy.sh prepare-nginx-ssl production

# Or directly
sh prepare-nginx-ssl.sh production
```

### Update Nginx proxy configuration

```bash
sh update-nginx-proxy-host.sh production
```

## Server Configuration

Your server configuration in `servers.json` must include:

```json
{
  "servers": [
    {
      "id": "production",
      "port": 3000,
      "key_path": "~/.ssh/your-ec2-key.pem",
      "user": "ec2-user",
      "host": "ec2-xx-xx-xx-xx.compute.amazonaws.com",
      "domain": "your-domain.com",
      "hostname": "127.0.0.1",
      "enabled": true
    }
  ]
}
```

The `domain` field is required for Nginx and SSL configuration.

## What Gets Installed

- **Nginx**: Installed using the appropriate package manager for your Linux distribution
- **Certbot**: For obtaining and managing SSL certificates
- **Firewall Rules**: Configured to allow HTTP, HTTPS, and your application port

## Nginx Configuration

The scripts create a basic Nginx configuration that:

1. Sets up a reverse proxy to your Node.js application
2. Configures SSL with Let's Encrypt (for HTTPS)
3. Sets up automatic certificate renewal

## Troubleshooting

### Domain Validation Issues

- Ensure your domain's DNS records point to your EC2 instance's IP address
- Make sure port 80 is open for Let's Encrypt validation

### Permission Issues

- Check SSH key permissions (`chmod 400 your-key.pem`)
- Ensure the user has sudo privileges

### Connection Issues

- Verify hostname/IP and SSH key path in `servers.json`
- Check that security groups allow SSH access (port 22)

## Next Steps

After setup, deploy your application and access it securely via HTTPS:

```bash
sh xdeploy.sh create production
```
