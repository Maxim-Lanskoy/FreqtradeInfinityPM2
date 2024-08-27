#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect the operating system
OS="$(uname -s)"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_NAME=$ID
else
    OS_NAME=$OS
fi

# Function to remove a package if it's installed
remove_package() {
    if [[ "$OS_NAME" =~ ^(ol|centos|rhel)$ ]]; then
        echo "🗑️ Removing $1 with dnf..."
        sudo dnf remove -y "$1"
        sudo dnf autoremove -y
    elif [ "$OS_NAME" = "Linux" ]; then
        echo "🗑️ Removing $1 with apt..."
        sudo apt-get remove --purge -y "$1"
        sudo apt-get autoremove -y
        sudo apt-get autoclean -y
    elif [ "$OS_NAME" = "Darwin" ]; then
        echo "🗑️ Removing $1 with brew..."
        brew uninstall "$1"
    fi
}

echo "🚀 Starting uninstallation..."

# Remove PM2 if installed
if command_exists pm2; then
    echo "🗑️ Removing PM2..."
    sudo npm uninstall -g pm2
    echo "✅ PM2 has been removed."
else
    echo "🔍 PM2 is not installed, skipping..."
fi

# Remove npm and Node.js if installed
if command_exists npm || command_exists node; then
    echo "🗑️ Removing Node.js and npm..."
    if [[ "$OS_NAME" =~ ^(ol|centos|rhel)$ ]]; then
        remove_package nodejs
    elif [ "$OS_NAME" = "Linux" ]; then
        remove_package nodejs
        sudo apt-get remove --purge -y npm
    elif [ "$OS_NAME" = "Darwin" ]; then
        brew uninstall node
    fi
    echo "✅ Node.js and npm have been removed."
else
    echo "🔍 Node.js and npm are not installed, skipping..."
fi

# Delete any remaining global npm directories
echo "🗑️ Removing global npm directories..."
sudo rm -rf /usr/local/lib/node_modules
sudo rm -rf ~/.npm
sudo rm -rf ~/.nvm

# Optionally remove NodeSource setup script (Linux only)
if [ "$OS_NAME" = "Linux" ]; then
    echo "🗑️ Removing NodeSource setup script if present..."
    sudo rm -f /etc/apt/sources.list.d/nodesource.list
fi

# Remove any residual configurations or data related to Node.js, npm, and pm2
echo "🗑️ Removing residual configurations and data..."
sudo rm -rf /usr/local/bin/pm2
sudo rm -rf /usr/local/bin/node
sudo rm -rf /usr/local/bin/npm
sudo rm -rf /usr/local/bin/npx
sudo rm -rf ~/.pm2

# Remove gettext (including envsubst) if installed
if command_exists envsubst; then
    echo "🗑️ Removing gettext (including envsubst)..."
    remove_package gettext
    echo "✅ gettext (including envsubst) has been removed."
else
    echo "🔍 gettext (including envsubst) is not installed, skipping..."
fi

echo "🎉 Uninstallation complete!"
