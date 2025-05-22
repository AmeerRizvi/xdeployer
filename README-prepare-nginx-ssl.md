# SSL Setup for Nginx

This document explains how to use the `prepare-nginx-ssl.sh` script to set up SSL certificates using Let's Encrypt for your Next.js applications.

## Quick Start

```bash
# Download the script
curl -L https://raw.githubusercontent.com/AmeerRizvi/xdeployer/main/prepare-nginx-ssl.sh -o prepare-nginx-ssl.sh
chmod +x prepare-nginx-ssl.sh

# Run the script
sh prepare-nginx-ssl.sh production
```

## What It Does

The script:

1. Connects to your EC2 instance via SSH
2. Installs Certbot (Let's Encrypt client)
3. Obtains SSL certificates for your domain and www subdomain
4. Configures Nginx to use HTTPS
5. Sets up automatic certificate renewal

## Requirements

- SSH access to your EC2 instance(s)
- A properly configured `servers.json` file
- `jq` installed on your local machine
- Nginx already set up on your EC2 instance (using `prepare-nginx.sh`)
- A valid domain name with DNS records pointing to your EC2 instance

## Usage

```bash
# Set up SSL for a specific server
sh prepare-nginx-ssl.sh production

# Set up SSL for all enabled servers
sh prepare-nginx-ssl.sh all
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
      "enabled": true
    }
  ]
}
```

The script requires the `domain` field to obtain SSL certificates.

## Installation Details

### Certbot

The script installs Certbot using the appropriate package manager for your Linux distribution:

- For Ubuntu, Debian: Uses `apt-get`
- For Amazon Linux, CentOS, RHEL: Uses `dnf` or `yum`

### SSL Certificates

The script obtains SSL certificates for:
- your-domain.com
- www.your-domain.com

### Auto-Renewal

The script sets up a cron job to automatically renew your certificates before they expire.

## How It Works

1. The script connects to your EC2 instance via SSH
2. It installs Certbot and its Nginx plugin
3. It runs Certbot in non-interactive mode to obtain certificates
4. Certbot automatically modifies your Nginx configuration to use HTTPS
5. It sets up a cron job for automatic renewal

## Troubleshooting

### Domain Validation Issues

If certificate validation fails:
- Make sure your domain's DNS records point to your EC2 instance's IP address
- Ensure that port 80 is open to the internet for the Let's Encrypt validation process
- Wait a few minutes for DNS changes to propagate if you recently updated records

### Permission Issues

If you encounter permission issues:
- Check SSH key permissions (`chmod 400 your-key.pem`)
- Ensure the user has sudo privileges on the EC2 instance

### Connection Issues

If you can't connect to your EC2 instance:
- Verify the hostname/IP address in `servers.json`
- Check that your security groups allow SSH access (port 22)
- Ensure your SSH key path is correct

### Installation Failures

If Certbot installation fails:
- Check the error message for specific issues
- Ensure your EC2 instance has internet access
- Try installing Certbot manually according to your Linux distribution

## Next Steps

After setting up SSL, you can:
1. Access your application securely via HTTPS (https://your-domain.com)
2. Test your SSL configuration using SSL Labs: https://www.ssllabs.com/ssltest/
3. Set up HTTP to HTTPS redirection if not already configured by Certbot
