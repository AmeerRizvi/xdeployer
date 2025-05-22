# View PM2 Logs for Next.js Applications

This document explains how to use the `xdeploy-view-logs.sh` script to view PM2 logs for your deployed Next.js applications.

## Quick Start

```bash
# Download the script
curl -L https://raw.githubusercontent.com/AmeerRizvi/xdeployer/main/xdeploy-view-logs.sh -o xdeploy-view-logs.sh
chmod +x xdeploy-view-logs.sh

# View logs for a specific server (last 100 lines by default)
sh xdeploy-view-logs.sh production

# View logs with a specific number of lines
sh xdeploy-view-logs.sh production 500
```

## What It Does

The script:

1. Connects to your server via SSH
2. Loads NVM if available (to ensure PM2 is in the path)
3. Displays the PM2 logs for your application
4. Shows the specified number of lines (defaults to 100)

This is useful for:
- Debugging application issues
- Monitoring application performance
- Checking for errors in production
- Verifying that your application is running correctly

## Requirements

- SSH access to your server(s)
- A properly configured `servers.json` file
- `jq` installed on your local machine
- PM2 installed on your server (typically installed by `xdeploy-setup-server.sh`)

## Usage

```bash
# Using xdeploy.sh
sh xdeploy.sh view-logs production

# With custom number of lines
sh xdeploy.sh view-logs production 500

# Or directly
sh xdeploy-view-logs.sh production
sh xdeploy-view-logs.sh production 200
```

## Server Configuration

Your `servers.json` file must include:

```json
{
  "servers": [
    {
      "id": "production",
      "name": "Production Server",
      "app_name": "my-nextjs-app",
      "key_path": "~/.ssh/your-key.pem",
      "user": "ec2-user",
      "host": "ec2-xx-xx-xx-xx.compute.amazonaws.com",
      "enabled": true
    }
  ]
}
```

The script requires the following fields:
- `app_name`: The name of the PM2 process to view logs for
- `key_path`: Path to your SSH key file
- `user`: SSH username
- `host`: Server hostname or IP address

## How It Works

1. The script connects to your server via SSH
2. It loads NVM if available (to ensure PM2 is in the path)
3. It runs the `pm2 logs` command with your application name
4. It displays the specified number of lines from the logs
5. The connection remains open, showing logs in real-time until you press Ctrl+C

## Troubleshooting

### Permission Issues

If you encounter permission issues:
- Check SSH key permissions (`chmod 400 your-key.pem`)
- Ensure the user has access to the PM2 logs

### Connection Issues

If you can't connect to your server:
- Verify the hostname/IP address in `servers.json`
- Check that your security groups allow SSH access (port 22)
- Ensure your SSH key path is correct

### PM2 Not Found

If PM2 is not found on the server:
- Make sure you've run `xdeploy-setup-server.sh` to install PM2
- Check if PM2 is installed globally: `npm list -g pm2`
- Try running the command manually on the server: `pm2 logs your-app-name`

### No Logs Available

If no logs are displayed:
- Verify that your application is running: `pm2 list`
- Check if the application name in `servers.json` matches the PM2 process name
- Try restarting your application: `pm2 restart your-app-name`

## Next Steps

After viewing logs, you might want to:
1. Update your application if you find issues: `sh xdeploy.sh update production`
2. Check server status: `sh xdeploy.sh info production`
3. Configure log rotation: PM2 log rotation is set up by `xdeploy-setup-server.sh`
