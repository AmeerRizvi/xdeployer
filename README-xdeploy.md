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

| Command                         | Description                                 |
| ------------------------------- | ------------------------------------------- |
| `create [server_id\|all]`       | Create a new deployment                     |
| `update [server_id\|all]`       | Update an existing deployment               |
| `list`                          | List available servers                      |
| `info [server_id]`              | Show server details                         |
| `setup-server [server_id\|all]` | Prepare server with Node.js, PM2, and Bun   |
| `setup-nginx [server_id\|all]`  | Set up Nginx as a reverse proxy             |
| `setup-ssl [server_id\|all]`    | Set up SSL certificates using Let's Encrypt |
| `update-nginx [server_id\|all]` | Update Nginx proxy configuration            |
| `add-domain [server_id\|all]`   | Add domain configuration to Nginx           |
| `view-logs [server_id] [lines]` | View PM2 logs for a specific server         |
| `version`                       | Show version information                    |

> **Note:** Missing scripts will be automatically downloaded from GitHub when needed.

## Options

| Option  | Description                                                      |
| ------- | ---------------------------------------------------------------- |
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
# Set up a server with Node.js, PM2, and Bun
sh xdeploy.sh setup-server production

# Set up all servers
sh xdeploy.sh setup-server all

# Set up Nginx on a specific server
sh xdeploy.sh setup-nginx production

# Set up SSL certificates
sh xdeploy.sh setup-ssl production

# Update Nginx proxy configuration
sh xdeploy.sh update-nginx production

# Add domain configuration to Nginx
sh xdeploy.sh add-domain production

# View PM2 logs
sh xdeploy.sh view-logs production

# View more lines of PM2 logs
sh xdeploy.sh view-logs production 500
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
    },
    {
      "id": "staging",
      "name": "Staging Server",
      "app_name": "my-nextjs-app-staging",
      "port": 3001,
      "key_path": "~/.ssh/your-ec2-key.pem",
      "user": "ubuntu",
      "host": "ec2-xx-xx-xx-xx.compute.amazonaws.com",
      "remote_dir": "/home/ubuntu/apps/my-nextjs-app-staging",
      "url": "http://your-staging-domain-or-ip:3001/",
      "pre_cmd": "DEV_ENV=true",
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
- `pre_cmd`: Environment variables or commands to prepend to PM2 start command

## Environment Variables with pre_cmd

The `pre_cmd` property allows you to set environment variables or prepend commands to the PM2 start command. This is useful for setting different environment configurations per server.

### Examples

#### Setting environment variables

```json
{
  "id": "staging",
  "name": "Staging Server",
  "app_name": "my-app-staging",
  "port": 3001,
  "pre_cmd": "DEV_ENV=true",
  "...": "other properties"
}
```

This will result in the PM2 command:

```bash
DEV_ENV=true PORT=3001 NODE_ENV=production node .next/standalone/server.js
```

#### Multiple environment variables

```json
{
  "id": "development",
  "name": "Development Server",
  "app_name": "my-app-dev",
  "port": 3002,
  "pre_cmd": "DEBUG=true LOG_LEVEL=debug",
  "...": "other properties"
}
```

This will result in the PM2 command:

```bash
DEBUG=true LOG_LEVEL=debug PORT=3002 NODE_ENV=production node .next/standalone/server.js
```

#### Database configuration

```json
{
  "id": "production",
  "name": "Production Server",
  "app_name": "my-app-prod",
  "port": 3000,
  "pre_cmd": "DATABASE_URL=postgresql://user:pass@prod-db:5432/myapp",
  "...": "other properties"
}
```

### How it works

1. When `pre_cmd` is specified in your server configuration, it gets extracted during deployment
2. The script prepends the `pre_cmd` to the PM2 start command using the format: `pm2_cmd="$pre_cmd $pm2_cmd"`
3. During deployment, you'll see "Pre-command: [your command]" in the output
4. When PM2 starts or restarts the application, it will use the environment variables from `pre_cmd`

### PM2 Update Behavior

When you update an existing deployment:

- PM2 will stop the existing process
- Start a new process with the updated environment variables
- The new environment variables will replace the old ones

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

### Environment Variable Issues

If your environment variables from `pre_cmd` are not working:

- Check the deployment output for "Pre-command: [your command]" to confirm it's being applied
- SSH into your server and check the PM2 process environment: `pm2 show your-app-name`
- Verify the environment variables are correctly formatted in `pre_cmd`
- Test the environment variables manually: `DEV_ENV=true node .next/standalone/server.js`
- Check PM2 logs for any environment-related errors: `pm2 logs your-app-name`
