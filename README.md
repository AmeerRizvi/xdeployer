# xdeployer

A simple, powerful deployment tool for Next.js applications to EC2 instances using PM2.

## Overview

xdeployer is a bash script that simplifies the deployment of Next.js applications to EC2 instances. It handles the build process, transfers the files to your server(s), and manages the application using PM2.

**Key Features:**
- Deploy to multiple servers with a single command
- Support for different package managers (npm, yarn, pnpm, bun)
- Automatic detection of your project's package manager
- Simple configuration via JSON
- Works with Next.js standalone output mode

## Requirements

- A Next.js application with `output: 'standalone'` in next.config.js
- SSH access to your EC2 instance(s)
- PM2 installed on your EC2 instance(s)
- jq installed on your local machine (for JSON parsing)
- zip installed on your local machine

## Installation

1. Copy the deployment files to your Next.js project:

```bash
# Using curl
curl -L https://github.com/yourusername/xdeployer/archive/main.tar.gz | tar xz --strip=1 xdeployer-main/run.sh xdeployer-main/servers.json.template

# Rename the template
mv servers.json.template servers.json
```

2. Make sure your Next.js project is configured for standalone output. Add this to your `next.config.js`:

```js
/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  // other config options...
};

module.exports = nextConfig;
```

3. Configure your servers in `servers.json`:

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
      "url": "http://your-domain-or-ip:3000/"
    }
  ]
}
```

## Usage

### Deploy to a server

```bash
# Create a new deployment
sh run.sh create production

# Update an existing deployment
sh run.sh update production
```

### Deploy to all servers

```bash
sh run.sh create all
```

### List available servers

```bash
sh run.sh list
```

### Show server details

```bash
sh run.sh info production
```

### Start development server after update

```bash
sh run.sh update production --dev
```

## Server Configuration

Each server in `servers.json` has the following properties:

| Property | Description |
|----------|-------------|
| `id` | Unique identifier for the server |
| `name` | Human-readable name |
| `app_name` | Name for the PM2 process |
| `port` | Port to run the Next.js app on |
| `key_path` | Path to your SSH key file |
| `user` | SSH username (e.g., ec2-user, ubuntu) |
| `host` | Server hostname or IP address |
| `remote_dir` | Directory on the server to deploy to |
| `url` | URL where the app will be accessible |

## EC2 Server Setup

Before deploying, make sure your EC2 instance has:

1. Node.js installed
2. PM2 installed globally (`npm install -g pm2`)
3. SSH access configured
4. Proper security group settings to allow traffic on your app's port

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
