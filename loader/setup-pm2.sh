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
    if [[ "$OS_NAME" =~ ^(ol|centos|rhel|fedora|ol8)$ ]]; then
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

# Enable EPEL release and install development tools on RHEL/CentOS/Fedora
if [[ "$OS_NAME" =~ ^(ol|centos|rhel|fedora|ol8)$ ]]; then
    echo "📦 Installing EPEL release..."
    install_package epel-release

    # Enable ol8_developer_EPEL repository for Oracle Linux
    if [[ "$OS_NAME" = "ol" ]]; then
        echo "🔄 Enabling ol8_developer_EPEL repository..."
        sudo dnf config-manager --enable ol8_developer_EPEL
    fi

    echo "📦 Installing Development Tools..."
    sudo dnf groupinstall -y "Development Tools"

    echo "📦 Installing gcc-c++ (g++ equivalent) and Python development tools..."
    install_package gcc-c++  # Correct package name for g++
    install_package python3.11-devel  # Ensure the package name is correct

    echo "📦 Installing sysstat for system performance monitoring..."
    install_package sysstat
fi

# Function to set Python 3.11 as the default version
set_default_python() {
    if command_exists python3.11; then
        echo "🔄 Setting Python 3.11 as the default Python version..."
        sudo ln -sf $(which python3.11) /usr/bin/python3
        sudo ln -sf $(which python3.11) /usr/bin/python
        if command_exists pip3.11; then
            sudo ln -sf $(which pip3.11) /usr/local/bin/pip3
            sudo ln -sf $(which pip3.11) /usr/local/bin/pip
        else
            echo "❌ pip3.11 not found, installing..."
            python3.11 -m ensurepip --upgrade
            sudo ln -sf $(which pip3.11) /usr/local/bin/pip3
            sudo ln -sf $(which pip3.11) /usr/local/bin/pip
        fi
        echo "✅ Default Python and pip have been updated to Python 3.11."
    fi
}

# Update the PATH variable for the current session
export PATH=/usr/local/bin:$PATH

# Check Python version
PYTHON_INSTALLED="false"
if command_exists python3; then
    PYTHON_VERSION=$(python3 --version | awk '{print $2}')
    if [[ "$(printf '%s\n' "3.9" "$PYTHON_VERSION" | sort -V | head -n1)" == "3.9" && "$PYTHON_VERSION" != "3.9" ]]; then
        echo "✅ Python version $PYTHON_VERSION is already installed."
        PYTHON_INSTALLED="true"
    else
        echo "⚠️ Python version is less than 3.9. Upgrading Python..."
        PYTHON_INSTALLED="false"
    fi
else
    echo "📦 Python3 is not installed. Installing Python 3.11..."
    PYTHON_INSTALLED="false"
fi

# Install Python if needed
if [ "$PYTHON_INSTALLED" = "false" ]; then
    if [[ "$OS_NAME" =~ ^(ol|centos|rhel|fedora|ol8)$ ]]; then
        sudo dnf install -y python3.11 python3.11-devel
    elif [ "$OS_NAME" = "ubuntu" ] || [ "$OS_NAME" = "debian" ]; then
        sudo apt update -y
        sudo apt install -y python3.11 python3.11-dev
    elif [ "$OS_NAME" = "Darwin" ]; then
        brew install python@3.11
    fi
    echo "✅ Python 3.11 has been installed."
    # Update python_installed_by_script flag in loader/last_update.txt
    sed -i 's/python_installed_by_script=false/python_installed_by_script=true/' loader/last_update.txt
    set_default_python
else
    # Ensure python_installed_by_script flag remains false in loader/last_update.txt
    sed -i 's/python_installed_by_script=true/python_installed_by_script=false/' loader/last_update.txt
fi

# Function to install remaining dependencies
install_dependencies() {
    echo "🚀 Starting setup..."

    # Install or update Node.js and npm
    if ! command_exists node || ! command_exists npm; then
        echo "📦 Node.js and npm are not installed. Installing now..."
        
        if [[ "$OS_NAME" =~ ^(ol|centos|rhel|fedora|ol8)$ ]]; then
            curl -sL https://rpm.nodesource.com/setup_18.x | sudo bash -
            install_package nodejs
        elif [ "$OS_NAME" = "ubuntu" ] || [ "$OS_NAME" = "debian" ]; then
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

        if [[ "$OS_NAME" =~ ^(ol|centos|rhel|fedora|ol8)$ ]]; then
            sudo npm install -g n
            sudo n stable
        elif [ "$OS_NAME" = "ubuntu" ] || [ "$OS_NAME" = "debian" ]; then
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
        if [[ "$OS_NAME" =~ ^(ol|centos|rhel|fedora|ol8)$ ]]; then
            install_package python3-pip
        elif [ "$OS_NAME" = "ubuntu" ] || [ "$OS_NAME" = "debian" ]; then
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
    if ! command_exists pip || ! pip show python-dotenv > /dev/null 2>&1; then
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
}

install_dependencies
