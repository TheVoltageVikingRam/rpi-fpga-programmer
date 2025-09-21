
<div align="center">

# 🚀 Raspberry Pi FPGA Programmer

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Raspberry%20Pi-red)](https://www.raspberrypi.org/)
[![Architecture](https://img.shields.io/badge/Arch-ARM64%20%7C%20ARMHF-blue)](https://www.raspberrypi.org/)
[![Digilent](https://img.shields.io/badge/Digilent-Adept-green)](https://digilent.com/)

**Transform your Raspberry Pi into a portable FPGA programming station!**

Program Xilinx FPGAs directly from your Pi with Digilent boards

[Installation](#-installation) • [Usage](#-usage) • [Supported Boards](#-supported-boards) • [Troubleshooting](#-troubleshooting)

</div>

---

## ✨ Features

<table>
<tr>
<td>

### 🎯 Key Benefits
- **🔧 One-Line Installation** - Automated setup script
- **📦 Complete Toolchain** - Runtime + Utilities included  
- **🔐 USB Permissions** - Auto-configured udev rules
- **💻 Multi-Architecture** - ARM64 & ARMHF support
- **🎮 Popular Boards** - Arty, Basys, Nexys & more

</td>
<td>

### 📋 What's Included
- Digilent Adept Runtime 2.27.9
- Digilent Adept Utilities 2.7.1
- USB device permissions
- JTAG programming tools
- Command-line interface

</td>
</tr>
</table>

## 🚀 Installation

### Quick Install (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/TheVoltageVikingRam/rpi-fpga-programmer/main/install.sh | bash
```
### Manual Installation

<details>
<summary>📖 Click to expand</summary>

```bash
# ================================
# Raspberry Pi FPGA Programmer - Manual Installation
# Digilent Adept Runtime & Utilities (ARM64/ARMHF)
# ================================

# 1. Check Raspberry Pi model and architecture
cat /proc/device-tree/model
dpkg --print-architecture   # should be arm64 or armhf

# 2. Clean up any broken installations
sudo dpkg --remove --force-remove-reinstreq digilent.waveforms digilent.adept.runtime digilent.adept.utilities
sudo apt --fix-broken install -y
sudo rm -f /etc/apt/sources.list.d/docker.list   # remove problematic docker repo if exists

# 3. Install dependencies
sudo apt update
sudo apt install -y wget curl libusb-1.0-0 libftdi1-2

# 4. Download Adept packages
# Option A: From GitHub repo (arm64 shown, replace with armhf if needed)
wget https://github.com/TheVoltageVikingRam/rpi-fpga-programmer/raw/main/digilent.adept.runtime_2.27.9-arm64.deb
wget https://github.com/TheVoltageVikingRam/rpi-fpga-programmer/raw/main/digilent.adept.utilities_2.7.1-arm64.deb

# Option B: From Digilent official website
# https://digilent.com/shop/software/digilent-adept/download/

# 5. Install Adept Runtime
sudo dpkg -i digilent.adept.runtime_*.deb
sudo apt install -f -y   # fix dependencies if needed

# 6. Install Adept Utilities
sudo dpkg -i digilent.adept.utilities_*.deb
sudo apt install -f -y

# 7. Set up USB permissions
sudo usermod -a -G dialout $USER

# Create udev rules
sudo tee /etc/udev/rules.d/99-digilent.rules > /dev/null << 'EOF'
# Digilent FPGA boards
SUBSYSTEM=="usb", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6010", MODE="0666", GROUP="dialout"
SUBSYSTEM=="usb", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6014", MODE="0666", GROUP="dialout"
SUBSYSTEM=="usb", ATTRS{idVendor}=="1443", MODE="0666", GROUP="dialout"
# Digilent USB Serial
SUBSYSTEM=="usb", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", MODE="0666", GROUP="dialout"
EOF

sudo udevadm control --reload-rules
sudo udevadm trigger

# 8. Reboot to apply permissions
sudo reboot
</details>
## 🔧 Usage

### Basic Commands

| Command | Description | Example |
|---------|-------------|---------|
| **Enumerate Devices** | List all connected FPGAs | `djtgcfg enum` |
| **Program FPGA** | Upload bitstream to device | `djtgcfg prog -d ArtyS7 -i 0 -f design.bit` |
| **Initialize Chain** | Setup JTAG chain | `djtgcfg init -d ArtyS7` |
| **Clear FPGA** | Erase configuration | `djtgcfg erase -d ArtyS7 -i 0` |

### Example Workflow

```bash
# 1. Check connected devices
$ djtgcfg enum
Found 1 device(s)

Device: ArtyS7
    Product Name:   Digilent Arty S7 - 25
    Serial Number:  210352BB8A3A

# 2. Initialize the device
$ djtgcfg init -d ArtyS7

# 3. Program your bitstream
$ djtgcfg prog -d ArtyS7 -i 0 -f my_design.bit
Programming device...
Programming succeeded.
```

## 📚 Supported Boards

<div align="center">

| Board Family | Model | Device Name | Status |
|:------------:|:-----:|:-----------:|:------:|
| **Arty** | S7-25/50 | `ArtyS7` | ✅ Tested |
| **Arty** | A7-35T/100T | `ArtyA7` | ✅ Supported |
| **Basys** | Basys 3 | `Basys3` | ✅ Supported |
| **Nexys** | A7 | `NexysA7` | ✅ Supported |
| **Nexys** | 4 DDR | `Nexys4DDR` | ✅ Supported |
| **Cmod** | A7 | `CmodA7` | ✅ Supported |
| **Zybo** | Z7 | `ZyboZ7` | ✅ Supported |

</div>

## 🐛 Troubleshooting

<details>
<summary>❌ <b>"libdmgr.so.2: cannot open shared object file"</b></summary>

**Problem:** Runtime library is missing

**Solution:** Install runtime BEFORE utilities
```bash
sudo dpkg -i digilent.adept.runtime_*-arm64.deb
sudo dpkg -i digilent.adept.utilities_*-arm64.deb
```
</details>

<details>
<summary>❌ <b>"No devices found"</b></summary>

**Problem:** FPGA not detected

**Solutions:**
1. Check USB cable and connection
2. Verify user permissions: `groups $USER`
3. Try with sudo: `sudo djtgcfg enum`
4. Reboot after installation
5. Check dmesg for USB errors: `dmesg | tail`
</details>

<details>
<summary>❌ <b>"Permission denied"</b></summary>

**Problem:** USB permissions not set

**Solution:** Add user to dialout group and reboot
```bash
sudo usermod -a -G dialout $USER
sudo reboot
```
</details>

## 🛠️ System Requirements

- **Hardware:** Raspberry Pi 3/4/5 or compatible ARM board
- **OS:** Raspberry Pi OS (32-bit or 64-bit)
- **Architecture:** ARM64 or ARMHF
- **Storage:** ~50MB free space
- **Connection:** USB port for FPGA board

## 📊 Version Compatibility

| Component | Version | Architecture | Status |
|-----------|---------|--------------|--------|
| Adept Runtime | 2.27.9 | ARM64 | ✅ Verified |
| Adept Runtime | 2.27.9 | ARMHF | ❓ May vary |
| Adept Utilities | 2.7.1 | ARM64 | ✅ Verified |
| Adept Utilities | 2.7.1 | ARMHF | ✅ Verified |

## 🤝 Contributing

We welcome contributions! Here's how you can help:

1. 🐛 **Report bugs** - [Open an issue](https://github.com/TheVoltageVikingRam/rpi-fpga-programmer/issues)
2. 💡 **Suggest features** - Share your ideas
3. 🔧 **Submit PRs** - Fix bugs or add features
4. 📖 **Improve docs** - Help others get started
5. ⭐ **Star the repo** - Show your support!

## 📄 License

This project is licensed under the MIT License. Digilent Adept tools are subject to [Digilent's license terms](https://digilent.com/).

## 🙏 Acknowledgments

- **Digilent** for Adept Runtime and Utilities
- **Raspberry Pi Foundation** for the amazing hardware
- **FPGA Community** for testing and feedback

---

<div align="center">

**Made with ❤️ for the FPGA community**

[Report Bug](https://github.com/TheVoltageVikingRam/rpi-fpga-programmer/issues) • [Request Feature](https://github.com/TheVoltageVikingRam/rpi-fpga-programmer/issues)

</div>
