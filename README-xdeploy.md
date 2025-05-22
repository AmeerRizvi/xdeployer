# xdeploy.sh - Next.js Deployment Script

This script is the core of the xdeployer toolkit, handling the deployment of Next.js applications to EC2 instances using PM2.

## Quick Start

```bash
# Create a new deployment
sh xdeploy.sh create production

# Update an existing deployment
sh xdeploy.sh update production
```

## Requirements

- A Next.js application with `output: 'standalone'` in next.config.js/ts
- SSH access to your EC2 instance(s)
- PM2 installed on your EC2 instance(s)
- jq installed on your local machine (for JSON parsing)
- zip installed on your local machine

## Commands

| Command | Description |
|---------|-------------|
| `create [server_id\|all]` | Create a new deployment |
| `update [server_id\|all]` | Update an existing deployment |
| `list` | List available servers |
| `info [server_id]` | Show server details |
| `prepare-ec2 [server_id\|all]` | Prepare EC2 instance with Node.js, PM2, and Bun |
| `prepare-nginx [server_id\|all]` | Set up Nginx as a reverse proxy |
| `version` | Show version information |

## Options

| Option | Description |
|--------|-------------|
| `--dev` | Start development server after update (only with update command) |

## Examples

### Deploy to a specific server

```bash
# Create a new deployment
sh xdeploy.sh create production

# Update an existing deployment
sh xdeploy.sh update production
```

### Deploy to all servers

```bash
# Create a new deployment on all enabled servers
sh xdeploy.sh create all

# Update all enabled servers
sh xdeploy.sh update all
```

### List and inspect servers

```bash
# List all configured servers
sh xdeploy.sh list

# Show details for a specific server
sh xdeploy.sh info production
```

### Prepare servers

```bash
# Prepare a specific EC2 instance
sh xdeploy.sh prepare-ec2 production

# Prepare all EC2 instances
sh xdeploy.sh prepare-ec2 all

# Set up Nginx on a specific server
sh xdeploy.sh prepare-nginx production
```

### Start development server after update

```bash
sh xdeploy.sh update production --dev
```

## How It Works

1. **Validation**: The script checks if your Next.js project is configured for standalone output
2. **Build**: Builds your Next.js application using the detected package manager (npm, yarn, pnpm, or bun)
3. **Package**: Creates a zip file of the standalone build
4. **Deploy**: Transfers the package to your server(s) and extracts it
5. **Start/Restart**: Uses PM2 to start or restart your application

## Server Configuration

Configure your servers in `servers.json`:

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
      "hostname": "127.0.0.1",
      "domain": "your-domain.com",
      "enabled": true
    }
  ]
}
```

### Required Properties

- `id`: Unique identifier for the server
- `name`: Human-readable name
- `app_name`: Name for the PM2 process
- `port`: Port to run the Next.js app on
- `key_path`: Path to your SSH key file
- `user`: SSH username (e.g., ec2-user, ubuntu)
- `host`: Server hostname or IP address
- `remote_dir`: Directory on the server to deploy to
- `enabled`: Whether the server is enabled for deployment (true/false)

### Optional Properties

- `url`: URL where the app will be accessible (for reference only)
- `hostname`: Hostname for the Next.js server
- `domain`: Domain name (required for Nginx setup)

## Troubleshooting

### Build Failures

If the build fails:
- Check your Next.js configuration
- Ensure you have the necessary dependencies installed
- Verify that your project builds locally with `npm run build`

### Deployment Failures

If deployment fails:
- Check your SSH key permissions (should be `chmod 400 your-key.pem`)
- Verify the server details in `servers.json`
- Ensure the remote directory is writable by the specified user
- Check that the server has Node.js and PM2 installed

### PM2 Issues

If PM2 fails to start or restart your application:
- SSH into your server and check PM2 logs: `pm2 logs your-app-name`
- Verify that PM2 is installed globally: `npm list -g pm2`
- Check if the port is already in use: `sudo lsof -i :3000`
