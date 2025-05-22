# Update Nginx Configuration

This document explains how to use the `xdeploy-update-nginx.sh` script to update the Nginx proxy configuration for your Next.js applications.

## Quick Start

```bash
# Download the script
curl -L https://raw.githubusercontent.com/AmeerRizvi/xdeployer/main/xdeploy-update-nginx.sh -o xdeploy-update-nginx.sh
chmod +x xdeploy-update-nginx.sh

# Run the script
sh xdeploy-update-nginx.sh production
```

## What It Does

The script:

1. Connects to your server via SSH
2. Locates the Nginx configuration file for your domain
3. Updates the `proxy_pass` directive to point to the hostname and port specified in your `servers.json`
4. Reloads Nginx to apply the changes

This is useful when:
- You've changed the internal IP address of your application server
- You want to point your domain to a different port
- You need to update the proxy configuration without reconfiguring the entire Nginx setup

## Requirements

- SSH access to your server(s)
- A properly configured `servers.json` file
- `jq` installed on your local machine
- Nginx already set up on your server (using `xdeploy-setup-nginx.sh`)

## Usage

```bash
# Using xdeploy.sh
sh xdeploy.sh update-nginx production

# Or directly
sh xdeploy-update-nginx.sh production

# Update proxy configuration for all enabled servers
sh xdeploy.sh update-nginx all
```

## Server Configuration

Your `servers.json` file must include:

```json
{
  "servers": [
    {
      "id": "production",
      "key_path": "~/.ssh/your-key.pem",
      "user": "ec2-user",
      "host": "ec2-xx-xx-xx-xx.compute.amazonaws.com",
      "domain": "your-domain.com",
      "hostname": "127.0.0.1",
      "port": 3000,
      "enabled": true
    }
  ]
}
```

The script requires the following fields:
- `domain`: The domain name used in the Nginx configuration file
- `hostname`: The internal hostname or IP to proxy to
- `port`: The port your application is running on

## How It Works

1. The script connects to your server via SSH
2. It locates the Nginx configuration file at `/etc/nginx/conf.d/your-domain.com.conf`
3. It uses `sed` to replace the existing `proxy_pass` directive with a new one pointing to your specified hostname and port
4. It reloads Nginx to apply the changes without downtime

## Troubleshooting

### Configuration File Not Found

If the script reports that the configuration file is not found:
- Make sure you've run `xdeploy-setup-nginx.sh` first to set up Nginx
- Check that the `domain` field in your `servers.json` matches the configuration file name

### No proxy_pass Line Found

If the script reports that no `proxy_pass` line was found:
- Check the Nginx configuration file manually to see if it has been modified
- You may need to run `xdeploy-setup-nginx.sh` again to recreate the configuration

### Permission Issues

If you encounter permission issues:
- Check SSH key permissions (`chmod 400 your-key.pem`)
- Ensure the user has sudo privileges on the server

### Connection Issues

If you can't connect to your server:
- Verify the hostname/IP address in `servers.json`
- Check that your security groups allow SSH access (port 22)
- Ensure your SSH key path is correct

## Next Steps

After updating the Nginx proxy configuration, you can:
1. Verify that your application is accessible at your domain
2. Check the Nginx logs for any errors: `sudo tail -f /var/log/nginx/error.log`
3. Test your application to ensure it's working correctly with the new proxy configuration
