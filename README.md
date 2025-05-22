# xdeployer

A simple, powerful deployment tool for Next.js applications to EC2 instances using PM2.

## Overview

xdeployer is a collection of bash scripts that simplify the deployment and management of Next.js applications on EC2 instances. The tools handle building, transferring files, configuring servers, and managing applications using PM2.

## Available Scripts

| Script                         | Description                                           |
| ------------------------------ | ----------------------------------------------------- |
| **xdeploy.sh**                 | Main deployment script for Next.js applications       |
| **prepare-ec2.sh**             | Prepares EC2 instances with Node.js, PM2, and Bun     |
| **prepare-nginx.sh**           | Sets up Nginx as a reverse proxy for your application |
| **prepare-nginx-ssl.sh**       | Configures SSL certificates using Let's Encrypt       |
| **update-nginx-proxy-host.sh** | Updates Nginx proxy configuration                     |

For detailed information on each script, see the corresponding README files:

- [README-xdeploy.md](README-xdeploy.md) - Main deployment script
- [README-prepare-ec2.md](README-prepare-ec2.md) - EC2 instance preparation
- [README-prepare-nginx.md](README-prepare-nginx.md) - Nginx setup
- [README-prepare-nginx-ssl.md](README-prepare-nginx-ssl.md) - SSL configuration
- [README-update-nginx-proxy-host.md](README-update-nginx-proxy-host.md) - Nginx proxy updates
- [README-install.md](README-install.md) - Installation script

## Requirements

- A Next.js application with `output: 'standalone'` in next.config.js/ts
- SSH access to your EC2 instance(s)
- jq installed on your local machine (for JSON parsing)
- zip installed on your local machine

## Quick Start

1. Download the deployment files:

```bash
curl -L https://github.com/AmeerRizvi/xdeployer/archive/main.tar.gz | tar xz --strip=1 xdeployer-main/xdeploy.sh xdeployer-main/servers.json.template
mv servers.json.template servers.json
```

2. Configure your servers in `servers.json`
3. Deploy your application:

```bash
# Create a new deployment
sh xdeploy.sh create production

# Update an existing deployment
sh xdeploy.sh update production
```

## Main Commands

```bash
# Deploy commands
sh xdeploy.sh create production    # Create new deployment
sh xdeploy.sh update production    # Update existing deployment

# Server management
sh xdeploy.sh list                 # List available servers
sh xdeploy.sh info production      # Show server details

# Server preparation
sh xdeploy.sh prepare-ec2 production      # Install Node.js, PM2, Bun
sh xdeploy.sh prepare-nginx production    # Set up Nginx
sh xdeploy.sh prepare-nginx-ssl production # Set up SSL with Let's Encrypt
sh xdeploy.sh update-nginx-proxy production # Update Nginx proxy configuration
```

> **Note:** Missing scripts will be automatically downloaded from GitHub when needed.

## Server Configuration

Each server in `servers.json` requires these properties:

| Property     | Description                      | Required |
| ------------ | -------------------------------- | -------- |
| `id`         | Unique identifier                | Yes      |
| `name`       | Human-readable name              | Yes      |
| `app_name`   | Name for PM2 process             | Yes      |
| `port`       | Application port                 | Yes      |
| `key_path`   | Path to SSH key file             | Yes      |
| `user`       | SSH username                     | Yes      |
| `host`       | Server hostname/IP               | Yes      |
| `remote_dir` | Deployment directory             | Yes      |
| `enabled`    | Enable/disable server            | Yes      |
| `url`        | Application URL                  | No       |
| `hostname`   | Next.js hostname                 | No       |
| `domain`     | Domain name (required for Nginx) | No\*     |

\*Required for Nginx/SSL setup

## License

MIT

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on contributing to this project.
