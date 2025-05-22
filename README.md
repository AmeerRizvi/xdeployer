# xdeployer

A simple, powerful deployment tool for Next.js applications to EC2 instances using PM2.

## Overview

xdeployer is a collection of bash scripts that simplify the deployment and management of Next.js applications on EC2 instances. The tools handle building, transferring files, configuring servers, and managing applications using PM2.

## Available Scripts

| Script                          | Description                                           |
| ------------------------------- | ----------------------------------------------------- |
| **xdeploy.sh**                  | Main deployment script for Next.js applications       |
| **xdeploy-setup-server.sh**     | Prepares servers with Node.js, PM2, and Bun           |
| **xdeploy-setup-nginx.sh**      | Sets up Nginx as a reverse proxy for your application |
| **xdeploy-setup-ssl.sh**        | Configures SSL certificates using Let's Encrypt       |
| **xdeploy-update-nginx.sh**     | Updates Nginx proxy configuration                     |
| **xdeploy-add-nginx-domain.sh** | Adds domain configuration to Nginx                    |
| **xdeploy-install.sh**          | Installation script for xdeployer                     |

For detailed information on each script, see the corresponding README files:

- [README-xdeploy.md](README-xdeploy.md) - Main deployment script
- [README-xdeploy-setup-server.md](README-xdeploy-setup-server.md) - Server setup and preparation
- [README-xdeploy-setup-nginx.md](README-xdeploy-setup-nginx.md) - Nginx setup
- [README-xdeploy-setup-ssl.md](README-xdeploy-setup-ssl.md) - SSL configuration
- [README-xdeploy-update-nginx.md](README-xdeploy-update-nginx.md) - Nginx proxy updates
- [README-xdeploy-add-nginx-domain.md](README-xdeploy-add-nginx-domain.md) - Adding domain to Nginx
- [README-xdeploy-install.md](README-xdeploy-install.md) - Installation script

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
chmod +x xdeploy.sh
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
sh xdeploy.sh setup-server production     # Install Node.js, PM2, Bun
sh xdeploy.sh setup-nginx production      # Set up Nginx
sh xdeploy.sh setup-ssl production        # Set up SSL with Let's Encrypt
sh xdeploy.sh update-nginx production     # Update Nginx proxy configuration
sh xdeploy.sh add-nginx-domain production  # Add domain configuration to Nginx
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
