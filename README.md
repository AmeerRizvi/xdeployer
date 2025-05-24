# xdeployer

A simple deployment tool for Next.js applications to EC2 instances using PM2.

xdeployer is a collection of bash scripts that simplify the deployment and management of Next.js applications on EC2 instances.

## Available Scripts

| Script                            | Description                                           |
| --------------------------------- | ----------------------------------------------------- |
| **xdeploy.sh**                    | Main deployment script for Next.js applications       |
| **xdeploy-setup-server.sh**       | Prepares servers with Node.js, PM2, and Bun           |
| **xdeploy-setup-nginx.sh**        | Sets up Nginx as a reverse proxy for your application |
| **xdeploy-setup-ssl.sh**          | Configures SSL certificates using Let's Encrypt       |
| **xdeploy-update-nginx-proxy.sh** | Updates Nginx proxy configuration                     |
| **xdeploy-add-domain.sh**         | Adds domain configuration to Nginx                    |
| **xdeploy-view-logs.sh**          | Views PM2 logs for a specific server                  |
| **xdeploy-update.sh**             | Updates xdeployer to the latest version               |

For detailed information on each script, see the corresponding README files:

- [README-xdeploy.md](README-xdeploy.md) - Main deployment script
- [README-xdeploy-setup-server.md](README-xdeploy-setup-server.md) - Server setup and preparation
- [README-xdeploy-setup-nginx.md](README-xdeploy-setup-nginx.md) - Nginx setup
- [README-xdeploy-setup-ssl.md](README-xdeploy-setup-ssl.md) - SSL configuration
- [README-xdeploy-update-nginx-proxy.md](README-xdeploy-update-nginx-proxy.md) - Nginx proxy updates
- [README-xdeploy-add-domain.md](README-xdeploy-add-domain.md) - Adding domain to Nginx
- [README-xdeploy-view-logs.md](README-xdeploy-view-logs.md) - Viewing PM2 logs
- [README-xdeploy-update.md](README-xdeploy-update.md) - Updating xdeployer

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

## Commands

```bash
# Deploy
sh xdeploy.sh create production
sh xdeploy.sh update production

# Server management
sh xdeploy.sh list
sh xdeploy.sh info production

# Server setup
sh xdeploy.sh setup-server production
sh xdeploy.sh setup-nginx production
sh xdeploy.sh setup-ssl production

# Other commands
sh xdeploy.sh update-nginx production
sh xdeploy.sh add-domain production
sh xdeploy.sh view-logs production
sh xdeploy.sh update-xdeploy
```

## Server Configuration

Configure your servers in `servers.json`:

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
| `domain`     | Domain name (required for Nginx) | No       |
| `pre_cmd`    | Environment variables for PM2    | No       |

## License

MIT

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on contributing to this project.
