# EC2 Instance Preparation for xdeployer

This document explains how to use the `prepare-ec2` command to set up your EC2 instances for Next.js deployment with xdeployer.

## Overview

The `prepare-ec2` command automates the installation of required software on your EC2 instances:

- **Node.js and npm**: For running JavaScript applications
- **PM2**: Process manager for Node.js applications
- **Bun**: Fast JavaScript runtime, bundler, transpiler, and package manager

This command saves you time by automatically detecting your Linux distribution and installing the appropriate packages.

## Installation

You can download the prepare-ec2 script directly using curl:

```bash
# Download the prepare-ec2 script
curl -L https://raw.githubusercontent.com/AmeerRizvi/xdeployer/main/prepare-ec2.sh -o prepare-ec2.sh

# Make it executable
chmod +x prepare-ec2.sh
```

If you've already installed xdeployer, the prepare-ec2 script is included and can be used through the main xdeploy.sh script.

## Requirements

- SSH access to your EC2 instance(s)
- A properly configured `servers.json` file with your server details
- `jq` installed on your local machine (for JSON parsing)

## Usage

You can use the prepare-ec2 functionality in two ways: through the main xdeploy.sh script or by using the prepare-ec2.sh script directly.

### Using xdeploy.sh (recommended)

#### Prepare a specific EC2 instance

```bash
sh xdeploy.sh prepare-ec2 production
```

This will connect to the server with ID "production" and install all required software.

#### Prepare all EC2 instances

```bash
sh xdeploy.sh prepare-ec2 all
```

This will prepare all enabled servers defined in your `servers.json` file.

### Using prepare-ec2.sh directly

If you've downloaded only the prepare-ec2.sh script, you can use it directly:

```bash
# Prepare a specific EC2 instance
sh prepare-ec2.sh production

# Prepare all EC2 instances
sh prepare-ec2.sh all
```

Note: When using the script directly, make sure you have a valid `servers.json` file in the same directory.

If you need a template for the servers.json file, you can download it with:

```bash
# Download the servers.json template
curl -L https://raw.githubusercontent.com/AmeerRizvi/xdeployer/main/servers.json.template -o servers.json

# Edit the file with your server details
nano servers.json
```

## What Gets Installed

### Node.js and npm

The script installs Node.js 22.x (the latest LTS version) and npm using the appropriate package manager for your Linux distribution:

- For Amazon Linux, CentOS, RHEL: Uses `yum`
- For Ubuntu, Debian: Uses `apt-get`

### PM2

PM2 is installed globally using npm:

```bash
sudo npm install -g pm2
```

PM2 is a production process manager for Node.js applications that allows you to:

- Keep applications alive forever
- Reload applications without downtime
- Manage application logging, monitoring, and clustering

### Bun

Bun is installed using the official installer:

```bash
curl -fsSL https://bun.sh/install | bash
```

Bun is added to the user's PATH for immediate use.

## Supported Linux Distributions

The script automatically detects and supports:

- Amazon Linux
- CentOS
- Red Hat Enterprise Linux (RHEL)
- Ubuntu
- Debian

For other distributions, you may need to install the required software manually.

## How It Works

1. The script connects to your EC2 instance via SSH
2. It detects the Linux distribution
3. It checks if each required software is already installed
4. It installs any missing software using the appropriate method
5. It verifies each installation by checking the version

## Troubleshooting

### Permission Issues

If you encounter permission issues, make sure:

- Your SSH key has the correct permissions (typically `chmod 400 your-key.pem`)
- The user specified in `servers.json` has sudo privileges on the EC2 instance

### Connection Issues

If you can't connect to your EC2 instance:

- Verify the hostname/IP address in `servers.json`
- Check that your security groups allow SSH access (port 22)
- Ensure your SSH key path is correct

### Installation Failures

If software installation fails:

- Check the error message for specific issues
- Ensure your EC2 instance has internet access
- Try installing the software manually to identify any specific issues

## Next Steps

After preparing your EC2 instance, you can deploy your Next.js application:

```bash
# Create a new deployment
sh xdeploy.sh create production

# Update an existing deployment
sh xdeploy.sh update production
```

## Manual Installation

If you prefer to install the required software manually, follow these steps:

### Node.js and npm

For Amazon Linux, CentOS, RHEL:

```bash
curl -fsSL https://rpm.nodesource.com/setup_22.x | sudo bash -
sudo yum install -y nodejs
```

For Ubuntu, Debian:

```bash
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### PM2

```bash
sudo npm install -g pm2
```

### Bun

```bash
curl -fsSL https://bun.sh/install | bash
```

Add Bun to your PATH:

```bash
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
```

Add these lines to your `~/.bashrc` or `~/.zshrc` to make the PATH change permanent.
