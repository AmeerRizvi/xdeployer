# Update xdeployer

This document explains how to update xdeployer to the latest version.

## Quick Start

```bash
# Update using xdeploy.sh (recommended)
sh xdeploy.sh update-xdeploy

# Or download and run the update script directly
curl -L https://raw.githubusercontent.com/AmeerRizvi/xdeployer/main/xdeploy-update.sh -o xdeploy-update.sh
chmod +x xdeploy-update.sh
sh xdeploy-update.sh
```

## What It Does

The update script:

1. **Downloads latest version**: Fetches the latest `xdeploy.sh` and `servers.json.template` from GitHub
2. **Preserves configuration**: Your existing `servers.json` configuration is never touched
3. **Makes executable**: Ensures the new `xdeploy.sh` script has execute permissions

## Requirements

- An existing xdeployer installation (must have `xdeploy.sh` in current directory)
- `curl` and `tar` commands available
- Internet connection to download from GitHub

## Usage

### Using xdeploy.sh (recommended)

```bash
sh xdeploy.sh update-xdeploy
```

### Using xdeploy-update.sh directly

```bash
sh xdeploy-update.sh
```

## What Gets Updated

- **xdeploy.sh**: The main deployment script with all latest features and bug fixes
- **servers.json.template**: Updated template with new configuration options

## What Stays the Same

- **servers.json**: Your server configuration is preserved
- **All other files**: No other files in your project are modified

## No Backups

The update process directly overwrites the existing files without creating backups. Your `servers.json` configuration file is always preserved.

## After Update

After updating, you can:

1. Check the version: `sh xdeploy.sh version`
2. See new commands: `sh xdeploy.sh` (shows help)
3. Continue using xdeployer as normal

## Troubleshooting

### Error: xdeploy.sh not found

Make sure you're running the update command from the directory containing your xdeployer installation.

### Download fails

Check your internet connection and ensure you can access GitHub. The update script downloads from:
`https://github.com/AmeerRizvi/xdeployer/archive/main.tar.gz`

### Permission denied

Make sure you have write permissions in the current directory.
