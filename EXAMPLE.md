# xdeployer Example Usage

This document provides a step-by-step example of how to use xdeployer with a Next.js project.

## 1. Create a Next.js Project

First, create a new Next.js project if you don't have one already:

```bash
# Using npm
npx create-next-app@latest my-nextjs-app
cd my-nextjs-app

# OR using yarn
yarn create next-app my-nextjs-app
cd my-nextjs-app

# OR using pnpm
pnpm create next-app my-nextjs-app
cd my-nextjs-app

# OR using bun
bun create next-app my-nextjs-app
cd my-nextjs-app
```

## 2. Configure Next.js for Standalone Output

Edit your `next.config.js` file to include the standalone output option:

```js
/** @type {import('next').NextConfig} */
const nextConfig = {
  output: "standalone",
  reactStrictMode: true
};

module.exports = nextConfig;
```

## 3. Install xdeployer

Download and install xdeployer:

```bash
# Using curl
curl -L https://github.com/AmeerRizvi/xdeployer/archive/main.tar.gz | tar xz
cd xdeployer-main
chmod +x install.sh
./install.sh
cd ..
```

## 4. Configure Your Servers

Edit the `servers.json` file that was created in your project root:

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

Replace the placeholder values with your actual EC2 instance details.

## 5. Prepare Your EC2 Instance

Make sure your EC2 instance has:

1. Node.js installed:

```bash
# For Amazon Linux 2
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs

# For Ubuntu
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

2. PM2 installed:

```bash
sudo npm install -g pm2
```

3. Create the deployment directory:

```bash
mkdir -p /home/ec2-user/apps/my-nextjs-app
```

## 6. Deploy Your Application

Now you can deploy your Next.js application to your EC2 instance:

```bash
# Create a new deployment
sh run.sh create production

# For subsequent updates
sh run.sh update production
```

## 7. Access Your Application

Your application should now be running on your EC2 instance at the URL specified in your `servers.json` file.

## 8. Managing Your Application with PM2

You can manage your application on the server using PM2:

```bash
# SSH into your server
ssh -i ~/.ssh/your-ec2-key.pem ec2-user@ec2-xx-xx-xx-xx.compute.amazonaws.com

# Check status
pm2 status

# View logs
pm2 logs my-nextjs-app

# Restart the application
pm2 restart my-nextjs-app

# Stop the application
pm2 stop my-nextjs-app

# Start the application
pm2 start my-nextjs-app
```
