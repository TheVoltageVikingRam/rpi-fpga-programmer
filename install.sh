#!/bin/bash
# Raspberry Pi FPGA Programmer - Automated Installation Script
# For Digilent Adept Runtime and Utilities on ARM64/ARMHF Raspberry Pi
# 
# Usage: curl -fsSL https://raw.githubusercontent.com/TheVoltageVikingRam/rpi-fpga-programmer/main/install.sh | bash

set -e

echo "🚀 Raspberry Pi FPGA Programming Station Setup"
echo "=============================================="
echo "Installing Digilent Adept Runtime and Utilities"
echo ""

# Check if running on Raspberry Pi
if ! grep -q "Raspberry Pi" /proc/device-tree/model 2>/dev/null; then
    echo "⚠️  Warning: This script is designed for Raspberry Pi"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check architecture
ARCH=$(dpkg --print-architecture)
echo "📋 Detected architecture: $ARCH"

if [[ "$ARCH" != "arm64" && "$ARCH" != "armhf" ]]; then
    echo "❌ Unsupported architecture: $ARCH"
    echo "   This script supports arm64 and armhf only."
    exit 1
fi

# Clean up any broken installations
echo "🧹 Cleaning up previous installations..."
sudo dpkg --remove --force-remove-reinstreq digilent.waveforms digilent.adept.runtime digilent.adept.utilities 2>/dev/null || true
sudo apt --fix-broken install -y >/dev/null 2>&1

# Remove problematic Docker repository if it exists
if [ -f /etc/apt/sources.list.d/docker.list ]; then
    echo "🗑️  Removing problematic Docker repository..."
    sudo rm -f /etc/apt/sources.list.d/docker.list
fi

sudo apt update >/dev/null 2>&1

# Install minimal dependencies (Qt5 not needed for command-line tools)
echo "📦 Installing dependencies..."
sudo apt install -y wget libusb-1.0-0 libftdi1-2 2>/dev/null || true

# Create temp directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

echo "⬇️  Downloading Digilent packages for $ARCH..."

# GitHub repository base URL
GITHUB_BASE="https://raw.githubusercontent.com/TheVoltageVikingRam/rpi-fpga-programmer/main"

# Download appropriate packages based on architecture
if [[ "$ARCH" == "arm64" ]]; then
    # Runtime from your GitHub repo
    RUNTIME_URL="${GITHUB_BASE}/packages/digilent.adept.runtime_2.27.9-arm64.deb"
    # Utilities from Digilent (or also host on your repo)
    UTILITIES_URL="https://digilent.s3.amazonaws.com/Software/AdeptUtilities/2.7.1/digilent.adept.utilities_2.7.1-arm64.deb"
    RUNTIME_FILE="digilent.adept.runtime_2.27.9-arm64.deb"
    UTILITIES_FILE="digilent.adept.utilities_2.7.1-arm64.deb"
else
    # For armhf, you'll need to host these files too if Digilent doesn't provide them
    echo "⚠️  ARMHF support: Checking for packages..."
    # Try to get from your repo first
    RUNTIME_URL="${GITHUB_BASE}/packages/digilent.adept.runtime_2.27.9-armhf.deb"
    UTILITIES_URL="${GITHUB_BASE}/packages/digilent.adept.utilities_2.7.1-armhf.deb"
    
    # Fallback to Digilent if not in your repo
    if ! wget --spider -q "$RUNTIME_URL" 2>/dev/null; then
        echo "   Falling back to Digilent servers for ARMHF..."
        RUNTIME_URL="https://digilent.s3.amazonaws.com/Software/Adept2Runtime/2.27.9/digilent.adept.runtime_2.27.9-armhf.deb"
        UTILITIES_URL="https://digilent.s3.amazonaws.com/Software/AdeptUtilities/2.7.1/digilent.adept.utilities_2.7.1-armhf.deb"
    fi
    
    RUNTIME_FILE="digilent.adept.runtime_2.27.9-armhf.deb"
    UTILITIES_FILE="digilent.adept.utilities_2.7.1-armhf.deb"
fi

# Download packages with progress and error handling
echo "  📥 Downloading Adept Runtime from repository..."
if ! wget -q --show-progress -O "$RUNTIME_FILE" "$RUNTIME_URL"; then
    echo "❌ Failed to download runtime package"
    echo "   URL: $RUNTIME_URL"
    exit 1
fi

echo "  📥 Downloading Adept Utilities..."
if ! wget -q --show-progress -O "$UTILITIES_FILE" "$UTILITIES_URL"; then
    echo "❌ Failed to download utilities package"
    echo "   URL: $UTILITIES_URL"
    exit 1
fi

# Verify downloads
echo "🔍 Verifying downloads..."
if [[ ! -f "$RUNTIME_FILE" ]] || [[ ! -s "$RUNTIME_FILE" ]]; then
    echo "❌ Runtime package download failed or is empty"
    exit 1
fi

if [[ ! -f "$UTILITIES_FILE" ]] || [[ ! -s "$UTILITIES_FILE" ]]; then
    echo "❌ Utilities package download failed or is empty"
    exit 1
fi

# Install packages
echo "📦 Installing Adept Runtime..."
if ! sudo dpkg -i "$RUNTIME_FILE"; then
    echo "⚠️  Fixing dependencies..."
    sudo apt install -f -y
    sudo dpkg -i "$RUNTIME_FILE"
fi

echo "📦 Installing Adept Utilities..."
if ! sudo dpkg -i "$UTILITIES_FILE"; then
    echo "⚠️  Fixing dependencies..."
    sudo apt install -f -y
    sudo dpkg -i "$UTILITIES_FILE"
fi

# Update library cache
sudo ldconfig

# Set up USB permissions
echo "🔐 Setting up USB permissions..."
sudo usermod -a -G dialout "$USER"

# Create udev rules
echo "📋 Creating udev rules..."
sudo tee /etc/udev/rules.d/99-digilent.rules > /dev/null << 'RULES_EOF'
# Digilent FPGA boards
SUBSYSTEM=="usb", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6010", MODE="0666", GROUP="dialout"
SUBSYSTEM=="usb", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6014", MODE="0666", GROUP="dialout"
SUBSYSTEM=="usb", ATTRS{idVendor}=="1443", MODE="0666", GROUP="dialout"
# Digilent USB Serial
SUBSYSTEM=="usb", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", MODE="0666", GROUP="dialout"
RULES_EOF

# Reload udev rules
sudo udevadm control --reload-rules
sudo udevadm trigger

# Clean up
cd /
rm -rf "$TEMP_DIR"

# Test installation
echo ""
echo "🧪 Testing installation..."
if command -v djtgcfg >/dev/null 2>&1; then
    echo "✅ djtgcfg installed successfully!"
    # Try to show version (might need USB permissions)
    djtgcfg --version 2>/dev/null || echo "   (Version check requires USB permissions - reboot needed)"
else
    echo "❌ Installation verification failed"
    echo "   djtgcfg command not found"
fi

echo ""
echo "✅ Installation completed successfully!"
echo ""
echo "📋 Next Steps:"
echo "1. 🔄 Reboot your Raspberry Pi to apply USB permissions:"
echo "   sudo reboot"
echo ""
echo "2. 🧪 After reboot, test the installation:"
echo "   djtgcfg enum"
echo ""
echo "3. 🔌 Connect your Digilent FPGA board and verify detection"
echo ""
echo "4. 🎯 Program .bit files with:"
echo "   djtgcfg prog -d [DeviceName] -i 0 -f your_design.bit"
echo ""
echo "📚 Common device names:"
echo "   • Arty S7:    ArtyS7"
echo "   • Arty A7:    ArtyA7" 
echo "   • Basys 3:    Basys3"
echo "   • Nexys A7:   NexysA7"
echo "   • Cmod A7:    CmodA7"
echo "   • Zybo Z7:    ZyboZ7"
echo ""
echo "📖 For more options: djtgcfg --help"
echo ""
echo "🎉 Your Raspberry Pi FPGA Programming Station is ready!"
echo ""

# Ask about reboot
read -p "🔄 Reboot now to apply changes? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🔄 Rebooting..."
    sudo reboot
else
    echo "⚠️  Remember to reboot before using: sudo reboot"
fi
