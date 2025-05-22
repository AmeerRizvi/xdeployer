# EC2 Instance Preparation for xdeployer

This document explains how to use the `prepare-ec2` script to set up your EC2 instances for Next.js deployment.

## Quick Start

```bash
# Download the script
curl -L https://raw.githubusercontent.com/AmeerRizvi/xdeployer/main/prepare-ec2.sh -o prepare-ec2.sh
chmod +x prepare-ec2.sh

# Or use through xdeploy.sh if you've installed the full package
sh xdeploy.sh prepare-ec2 production
```

## What It Does

The script automatically installs and configures:

- **Node.js 22.x and npm**: For running JavaScript applications
- **PM2**: Process manager with log rotation configured
- **Bun**: Fast JavaScript runtime and package manager

## Requirements

- SSH access to your EC2 instance(s)
- A properly configured `servers.json` file
- `jq` installed on your local machine

## Usage

### Using xdeploy.sh (recommended)

```bash
# Prepare a specific EC2 instance
sh xdeploy.sh prepare-ec2 production

# Prepare all EC2 instances
sh xdeploy.sh prepare-ec2 all
```

### Using prepare-ec2.sh directly

```bash
# Prepare a specific EC2 instance
sh prepare-ec2.sh production

# Prepare all EC2 instances
sh prepare-ec2.sh all
```

## Server Configuration

Your `servers.json` file should include:

```json
{
  "servers": [
    {
      "id": "production",
      "key_path": "~/.ssh/your-ec2-key.pem",
      "user": "ec2-user",
      "host": "ec2-xx-xx-xx-xx.compute.amazonaws.com",
      "enabled": true
    }
  ]
}
```

## Installation Details

### Node.js and npm

- Installs Node.js 22.x (latest LTS)
- Upgrades if older version is detected
- Skips if version 22.x or newer is already installed

### PM2

- Installs PM2 globally
- Configures PM2 log rotation with:
  - Daily rotation (at midnight)
  - No log deletion (logs kept forever)
  - 10MB maximum log file size
  - Compressed log archives

### Bun

- Installs the latest version
- Updates if already installed
- Adds to PATH in .bashrc and/or .zshrc

## Supported Linux Distributions

- Amazon Linux
- CentOS
- Red Hat Enterprise Linux (RHEL)
- Ubuntu
- Debian

## Troubleshooting

### Permission Issues

- Check SSH key permissions (`chmod 400 your-key.pem`)
- Ensure the user has sudo privileges

### Connection Issues

- Verify hostname/IP and SSH key path in `servers.json`
- Check that security groups allow SSH access (port 22)

### Installation Failures

- Check error messages for specific issues
- Ensure the EC2 instance has internet access

## Next Steps

After preparing your EC2 instance, deploy your Next.js application:

```bash
sh xdeploy.sh create production
```

## Manual Installation

If you prefer to install manually:

```bash
# Node.js (Amazon Linux, CentOS, RHEL)
curl -fsSL https://rpm.nodesource.com/setup_22.x | sudo bash -
sudo yum install -y nodejs

# Node.js (Ubuntu, Debian)
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs

# PM2 with log rotation
sudo npm install -g pm2@latest
pm2 install pm2-logrotate
pm2 set pm2-logrotate:max_size 10M
pm2 set pm2-logrotate:retain all
pm2 set pm2-logrotate:compress true
pm2 set pm2-logrotate:rotateInterval "0 0 * * *"

# Bun
curl -fsSL https://bun.sh/install | bash
```
