# xdeployer Installation Script

This document explains how to use the `install.sh` script to set up xdeployer in your Next.js project.

## Quick Start

```bash
# Download the xdeployer repository
curl -L https://github.com/AmeerRizvi/xdeployer/archive/main.tar.gz | tar xz

# Navigate to the xdeployer directory
cd xdeployer-main

# Run the installation script
sh install.sh

# Return to your project directory
cd ..
```

## What It Does

The script:

1. Checks if you're in a Next.js project (by looking for package.json)
2. Verifies if jq and zip are installed (warns if not)
3. Copies xdeploy.sh to your project directory
4. Copies servers.json.template to your project directory as servers.json
5. Checks if next.config.js exists and has standalone output configuration
6. Creates a next.config.js with standalone output if none exists

## Requirements

- A Next.js project (with package.json)
- jq and zip installed (optional, but recommended)

## After Installation

After running the installation script, you'll need to:

1. Edit the servers.json file to configure your deployment targets
2. Make sure your Next.js project is configured for standalone output
3. Deploy your application using xdeploy.sh

## Configuration

### servers.json

Edit the servers.json file to configure your deployment targets:

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
      "domain": "your-domain.com",
      "hostname": "127.0.0.1",
      "enabled": true
    }
  ]
}
```

### next.config.js

Make sure your Next.js project is configured for standalone output:

```js
/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  // other config options...
};

module.exports = nextConfig;
```

## Troubleshooting

### Missing Dependencies

If the script warns about missing dependencies:

- Install jq:
  - macOS: `brew install jq`
  - Ubuntu/Debian: `sudo apt-get install jq`
  - CentOS/RHEL: `sudo yum install jq`

- Install zip:
  - macOS: `brew install zip`
  - Ubuntu/Debian: `sudo apt-get install zip`
  - CentOS/RHEL: `sudo yum install zip`

### Not a Next.js Project

If the script reports that no package.json was found:
- Make sure you're running the script in a Next.js project directory
- Create a basic package.json if you're starting a new project

### Next.js Configuration Issues

If the script warns about missing standalone output configuration:
- Edit your next.config.js to include `output: 'standalone'`
- This is required for xdeployer to work correctly

## Next Steps

After installation, you can deploy your Next.js app:

```bash
# Create a new deployment
sh xdeploy.sh create your-server-id

# Update an existing deployment
sh xdeploy.sh update your-server-id
```

For more information, see the main [README.md](README.md) file.
