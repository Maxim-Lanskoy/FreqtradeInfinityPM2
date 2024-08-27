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

# Function to install a package if it's not installed
install_package() {
    if [[ "$OS_NAME" =~ ^(ol|centos|rhel)$ ]]; then
        echo "🔄 Installing $1 with dnf..."
        sudo dnf install -y "$1"
    elif [ "$OS_NAME" = "Linux" ]; then
        echo "🔄 Installing $1 with apt..."
        sudo apt install -y "$1"
    elif [ "$OS_NAME" = "Darwin" ]; then
        echo "🔄 Installing $1 with brew..."
        brew install "$1"
    fi
}

echo "🚀 Starting setup..."

# Install or update Node.js and npm
if ! command_exists node || ! command_exists npm; then
    echo "📦 Node.js and npm are not installed. Installing now..."
    
    if [[ "$OS_NAME" =~ ^(ol|centos|rhel)$ ]]; then
        curl -sL https://rpm.nodesource.com/setup_18.x | sudo bash -
        install_package nodejs
    elif [ "$OS_NAME" = "Linux" ]; then
        sudo apt update -y
        curl -sL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        install_package nodejs
    elif [ "$OS_NAME" = "Darwin" ]; then
        brew update
        brew install node
    fi

    echo "✅ Node.js and npm have been installed."
else
    echo "🔍 Node.js and npm are already installed. Checking for updates..."

    if [[ "$OS_NAME" =~ ^(ol|centos|rhel)$ ]]; then
        sudo npm install -g n
        sudo n stable
    elif [ "$OS_NAME" = "Linux" ]; then
        sudo npm install -g n
        sudo n stable
    elif [ "$OS_NAME" = "Darwin" ]; then
        brew upgrade node
    fi
    
    echo "🔄 Node.js and npm have been updated to the latest stable version."
fi

# Install or update PM2
if ! command_exists pm2; then
    echo "📦 PM2 is not installed. Installing PM2 globally..."
    sudo npm install pm2@latest -g
    echo "✅ PM2 has been installed."
else
    echo "🔍 PM2 is already installed. Checking for updates..."
    sudo npm install pm2@latest -g
    echo "🔄 PM2 has been updated to the latest version."
fi

# Check if pip is installed
if ! command_exists pip; then
    echo "📦 pip is not installed. Installing pip now..."
    if [[ "$OS_NAME" =~ ^(ol|centos|rhel)$ ]]; then
        install_package python3-pip
    elif [ "$OS_NAME" = "Linux" ]; then
        sudo apt update -y
        install_package python3-pip
    elif [ "$OS_NAME" = "Darwin" ]; then
        brew install python3
    fi
    echo "✅ pip has been installed."
else
    echo "🔍 pip is already installed."
fi

# Install or update python-dotenv
if ! pip show python-dotenv > /dev/null 2>&1; then
    echo "📦 python-dotenv is not installed. Installing python-dotenv..."
    pip install python-dotenv
    echo "✅ python-dotenv has been installed."
else
    echo "🔍 python-dotenv is already installed. Checking for updates..."
    pip install --upgrade python-dotenv
    echo "🔄 python-dotenv has been updated to the latest version."
fi

# Install or update gettext (envsubst)
if ! command_exists envsubst; then
    echo "📦 gettext (including envsubst) is not installed. Installing now..."
    install_package gettext
    echo "✅ gettext has been installed."
else
    echo "🔍 gettext (including envsubst) is already installed."
fi

echo "🎉 Setup complete!"
