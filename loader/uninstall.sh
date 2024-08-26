#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Remove PM2 if installed
if command_exists pm2; then
    echo "Removing PM2..."
    sudo npm uninstall -g pm2
    echo "PM2 has been removed."
else
    echo "PM2 is not installed, skipping..."
fi

# Remove npm and Node.js if installed
if command_exists npm || command_exists node; then
    echo "Removing Node.js and npm..."
    sudo apt-get remove --purge -y nodejs npm
    sudo apt-get autoremove -y
    sudo apt-get autoclean -y
    echo "Node.js and npm have been removed."
else
    echo "Node.js and npm are not installed, skipping..."
fi

# Delete any remaining global npm directories
echo "Removing global npm directories..."
sudo rm -rf /usr/local/lib/node_modules
sudo rm -rf ~/.npm
sudo rm -rf ~/.nvm

# Optionally remove NodeSource setup script
echo "Removing NodeSource setup script if present..."
sudo rm -f /etc/apt/sources.list.d/nodesource.list

# Remove any residual configurations or data related to Node.js, npm, and pm2
echo "Removing residual configurations and data..."
sudo rm -rf /usr/local/bin/pm2
sudo rm -rf /usr/local/bin/node
sudo rm -rf /usr/local/bin/npm
sudo rm -rf /usr/local/bin/npx
sudo rm -rf ~/.pm2

echo "All Node.js, npm, and PM2 components have been removed."
