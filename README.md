# Android 16 Terminal Debian GUI Access Tool

![Bash](https://img.shields.io/badge/Shell-Bash-green) ![Debian](https://img.shields.io/badge/OS-Debian%2012-red) ![VNC](https://img.shields.io/badge/Protocol-VNC-blue)

**Chinese Documentation**: [README_CN.md](README_CN.md)

## Feature Overview

This script is specifically designed for terminal environments on Android 16 systems, enabling quick configuration of graphical interface access for Debian 12. After configuration, you can access the native Debian 12 GUI environment within the Android terminal from your PC through the following steps:

1. Run this script in the Android terminal to complete configuration
2. Execute `adb forward tcp:5901 tcp:5901` on your PC for port forwarding
3. Connect using any VNC client to `localhost:5901`

## Key Features

- **One-click Configuration**: Automates installation and configuration of all necessary components
- **SSH Access**: Configures SSH service with modified default port 10022
- **GUI Support**: Installs full desktop environment and VNC server
- **Smart Detection**: Automatically skips completed configuration steps
- **UTF-8 Locale Check**: Prevents redundant locale configuration
- **Detailed Logging**: Color-coded messages for different operation levels

## Usage Guide

### Prerequisites

- Android 16 system terminal environment

### Installation Steps

1. Save the script to your Android terminal device (e.g., `android16-terminal.sh`)
2. Grant execution permissions:
   ```bash
   chmod +x android16-terminal.sh
   ```
3. Execute the script:
   ```bash
   ./android16-terminal.sh
   ```

### PC Connection Steps

1. Ensure Android device is connected via USB
2. Perform port forwarding on PC:
   ```bash
   adb forward tcp:5901 tcp:5901
   ```
3. Open VNC client and connect to:
   ```
   localhost:5901
   ```
4. Enter the VNC password set during script execution

## Script Function Details

The script performs the following configurations sequentially:

1. **System Updates**: Refresh package lists
2. **SSH Service Configuration**:
   - Install OpenSSH server
   - Modify SSH port to 10022
   - Enable password authentication
3. **Locale Settings**:
   - Install locales package
   - Prompt for UTF-8 locale setup only when unconfigured
4. **Desktop Environment Installation**:
   - Install tasksel utility
   - Deploy full desktop environment
5. **VNC Server Configuration**:
   - Install TigerVNC server
   - Set VNC password (first-run only)
   - Configure VNC server parameters
   - Enable automatic startup on boot

## Important Notes

1. VNC password setup prompt appears during first execution - remember your credentials
2. Script may require multiple confirmations during execution - follow on-screen instructions
3. Recommended to run in stable network environment for reliable package downloads
4. After configuration, manage VNC service with:
   - Start: `sudo systemctl start tigervncserver@:1.service`
   - Stop: `sudo systemctl stop tigervncserver@:1.service`
   - Check status: `sudo systemctl status tigervncserver@:1.service`

## Contribution & Feedback

We welcome Issues and Pull Requests to improve this project. Please provide detailed error descriptions and reproduction steps when reporting issues.

## License

This project is open-sourced under [MIT License](LICENSE).
