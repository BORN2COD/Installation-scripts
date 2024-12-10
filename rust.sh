# Installation-scripts

#!/bin/bash

# Define Rust installation directories
RUSTUP_HOME="$HOME/.rustup"
CARGO_HOME="$HOME/.cargo"

# Load Rust environment variables
load_rust_env() {
    export RUSTUP_HOME="$HOME/.rustup"
    export CARGO_HOME="$HOME/.cargo"
    export PATH="$CARGO_HOME/bin:$PATH"
    source "$CARGO_HOME/env" 2>/dev/null
}

# Function to install system dependencies required by Rust
install_dependencies() {
    echo "Installing system dependencies for Rust..."
    if command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y build-essential libssl-dev curl
    elif command -v yum &> /dev/null; then
        sudo yum groupinstall 'Development Tools' && sudo yum install -y openssl-devel curl
    elif command -v dnf &> /dev/null; then
        sudo dnf groupinstall 'Development Tools' && sudo dnf install -y openssl-devel curl
    elif command -v pacman &> /dev/null; then
        sudo pacman -Syu base-devel openssl curl
    else
        echo "No supported package manager found. Manually install dependencies."
        exit 1
    fi
}

# Install system dependencies
install_dependencies

# Install or Update Rust
if command -v rustup &> /dev/null; then
    echo "Rust is already installed. Would you like to reinstall or update it? [y/N]"
    read -p ">" choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        echo "Reinstalling Rust..."
        rustup self uninstall -y
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    else
        echo "Skipping reinstallation."
    fi
else
    echo "Rust not found. Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

# Ensure the environment is loaded properly
load_rust_env

# Fix permissions (current user only - avoid unnecessary sudo)
if [ -d "$RUSTUP_HOME" ]; then
    chmod -R 755 "$RUSTUP_HOME"
fi

if [ -d "$CARGO_HOME" ]; then
    chmod -R 755 "$CARGO_HOME"
fi

# Retry logic for Cargo availability
max_retries=3
for ((i=0; i<max_retries; i++)); do
    if command -v cargo &> /dev/null; then
        echo "Cargo is ready!"
        break
    else
        echo "Attempting to source Cargo environment..."
        source "$CARGO_HOME/env"
        sleep 2
    fi
done

if ! command -v cargo &> /dev/null; then
    echo "Cargo still not found after retries. Please run: source $HOME/.cargo/env"
    exit 1
fi

# Ensure Rust environment is in shell profile
PROFILE_FILE=""
if [[ "$SHELL" == *"zsh"* ]]; then
    PROFILE_FILE="$HOME/.zshrc"
else
    PROFILE_FILE="$HOME/.bashrc"
fi

if ! grep -q "CARGO_HOME" "$PROFILE_FILE"; then
    echo "Adding Rust environment variables to $PROFILE_FILE"
    {
        echo 'export RUSTUP_HOME="$HOME/.rustup"'
        echo 'export CARGO_HOME="$HOME/.cargo"'
        echo 'export PATH="$CARGO_HOME/bin:$PATH"'
        echo 'source "$CARGO_HOME/env"'
    } >> "$PROFILE_FILE"
fi

echo "Reloading shell environment..."
source "$PROFILE_FILE"
load_rust_env

# Final feedback
echo "Rust installation and environment setup are complete!"
rustc --version
cargo --version
