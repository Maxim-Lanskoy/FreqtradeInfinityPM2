#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install or update Node.js and npm
if ! command_exists node || ! command_exists npm; then
    echo "Node.js and npm are not installed. Installing now..."
    
    # Update package index
    sudo apt update -y

    # Install Node.js and npm
    curl -sL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt install -y nodejs

    echo "Node.js and npm have been installed."
else
    echo "Node.js and npm are already installed. Checking for updates..."

    # Update Node.js and npm to the latest version
    sudo npm install -g n
    sudo n stable
    
    echo "Node.js and npm have been updated to the latest stable version."
fi

# Install or update PM2
if ! command_exists pm2; then
    echo "PM2 is not installed. Installing PM2 globally..."
    sudo npm install pm2@latest -g
    echo "PM2 has been installed."
else
    echo "PM2 is already installed. Checking for updates..."

    # Update PM2 to the latest version
    sudo npm install pm2@latest -g
    echo "PM2 has been updated to the latest version."
fi

echo "Setup complete."
