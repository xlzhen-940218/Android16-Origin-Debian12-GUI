## AD FocuSee  [Record Your Screen. Get Polished Videos Automatically.](https://focusee.imobie.com?ad=github-xlzhen)

# Android 16 Terminal Debian GUI Access Tool

**Chinese Documentation**: [README_CN.md](README_CN.md)

## Feature Overview

This script is specifically designed for Linux virtual machine/terminal environments on Android 16 systems. It enables quick, automated configuration of a full graphical interface (GUI) for **Debian 12 (Bookworm)** and **Debian 13 (Trixie)**. It tackles deep system-level compatibility issues between Android and Debian, allowing you to seamlessly access the native Debian GUI directly on your phone or from your PC.

## Key Features

* **Bilingual Interface**: Fully supports English and Chinese UI during execution.
* **Debian 13 & Wayland Compatibility**: Automatically forces X11 sessions for VNC to prevent black screens caused by Debian 13's default Wayland environments.
* **Deep Android VM Integration**:
* Applies a network bridge stability patch to fix random VNC/SSH disconnections.
* Automatically maps the Android `/mnt/shared` directory to the Linux Desktop as an independent disk.


* **Global Locale & IME Fixes**: Resolves the Android `C.UTF-8` locale issue, installs CJK fonts, and integrates the **Fcitx5** input method framework.
* **One-click Software Suite**: Optionally installs a full productivity suite including Chromium, LibreOffice, VLC, GIMP, Flameshot, and essential system tools (htop, git, curl).
* **Secure Remote Access**: Configures SSH (forced IPv4 on custom port 10022) and TigerVNC (port 5901).
* **Wireless Audio Streaming**: Overcomes the lack of physical audio mapping in the Android 16 Linux VM using a low-latency PulseAudio TCP streaming solution. Works seamlessly with the companion Android app [Simple Protocol Player](https://github.com/xlzhen-940218/SimpleProtocolPlayer) to play desktop audio directly on your phone's speakers.

## Usage Guide

### Prerequisites

* Android 16 system terminal/VM environment.
* A regular user account (Do **not** run the script as root, it will automatically request `sudo` privileges when needed).

### Installation Steps

1. Save the script to your Android terminal device (e.g., `android16-terminal.sh`).
2. Grant execution permissions:
```bash
chmod +x android16-terminal.sh

```


3. Execute the script:
```bash
./android16-terminal.sh

```


4. Follow the interactive prompts to select your preferred language, Desktop Environment (KDE, GNOME, XFCE, etc.), set up a VNC password, and choose optional software components.

## Connection Methods

### Method 1: On Windows PC (Recommended, via ADB Forwarding)

1. Ensure your Android device is connected to your PC via USB and **USB Debugging** is enabled in Developer Options.
2. Open Windows CMD or PowerShell and set up port forwarding:
```bash
adb forward tcp:5901 tcp:5901

```


3. Open any VNC client (e.g., TigerVNC) on your PC and connect to:
```
127.0.0.1:5901

```



### Method 2: Direct Access on Phone

1. Download and install a VNC client app, such as **AVNC**, on your Android phone.
2. Create a new connection with the address: `127.0.0.1` and port: `5901`.
3. Connect and enter the VNC password you set during the script execution.

## 🔊 Audio Solution (Fix Missing Sound in VNC)

Android 16's native Linux VM (Terminal / AVF) does not currently provide virtual sound card mapping or virtio-sound hardware passthrough. As a result, playing videos, music, or browser audio inside the VNC desktop produces no sound by default.

This is solved by using **PulseAudio TCP Simple Protocol** to stream audio from the Debian VM to your Android phone over loopback:

### 1. Install Android Audio Client

Download and install the dedicated PulseAudio player **Simple Protocol Player** on your Android phone:
- 📥 **Download APK**: [Simple Protocol Player Releases](https://github.com/xlzhen-940218/SimpleProtocolPlayer/releases)
- GitHub Repo: [xlzhen-940218/SimpleProtocolPlayer](https://github.com/xlzhen-940218/SimpleProtocolPlayer)

### 2. Start Audio Server in Debian VM

Run the following command in the Debian terminal (installs utilities and loads the streaming module):

```bash
# Ensure pactl tool is installed
sudo apt install -y pulseaudio-utils

# Load audio streaming module on port 12345
pactl load-module module-simple-protocol-tcp rate=44100 format=s16le channels=2 record=true port=12345
```

> 💡 **Tip**: To start the audio server automatically on boot or terminal startup, append the `pactl load-module ...` command above to the end of your `~/.bashrc`.

### 3. Connect on Phone & Listen

1. Open **Simple Protocol Player** on your Android phone.
2. Configure settings:
   - **IP Address**: `127.0.0.1` (Android host shares local loopback with the VM)
   - **Audio Port**: `12345`
   - **Mode**: Select **Speaker (Receiver)**
   - **Format**: Default 44100Hz / Stereo / 50ms buffer
3. Tap **Start Stream**. Audio from your Debian VNC desktop will now play smoothly through your phone's speakers!
4. *(Bonus)*: Supports "Microphone (Transmitter)" mode as well, allowing you to use your phone mic as virtual mic input in Debian.

## 🛠️ Troubleshooting & FAQ

* **VNC connection drops, times out, or shows a black screen randomly?**
This is almost always caused by Android's aggressive background task killing. Go to Android **Settings** -> **Apps** -> Find your Terminal/VM App -> Set **Battery Optimization** to **Unrestricted**. If it drops, completely close the terminal app from the recent tasks menu and reopen it.
* **Cannot type Chinese or Fcitx5 is not showing?**
The input method framework requires a desktop restart to take effect. Either restart your terminal app entirely or run `vncserver -kill :1 && vncserver :1` to restart the VNC session.
* **The "Android_Files" shared folder is empty or gives "Permission Denied"?**
Ensure your Android Terminal/VM app has been granted the **All Files Access / Storage** permission in Android Settings. If the mount still fails, restart your phone to reset the Android VirtioFS mounts.
* **No audio when playing videos or browser media in VNC desktop?**
The Android 16 Linux VM does not feature native sound card passthrough. Follow the **Audio Solution** section above by running `pactl load-module module-simple-protocol-tcp ...` in Debian and pairing it with the [Simple Protocol Player](https://github.com/xlzhen-940218/SimpleProtocolPlayer) app on your phone.

## Important Notes

* Manage the VNC service manually if needed:
* Start: `sudo systemctl start tigervncserver@:1.service`
* Stop: `sudo systemctl stop tigervncserver@:1.service`
* Check status: `sudo systemctl status tigervncserver@:1.service`


* SSH can be accessed locally or via ADB forwarding (`adb forward tcp:10022 tcp:10022`) using: `ssh username@127.0.0.1 -p 10022`.

## Contribution & Feedback

We welcome Issues and Pull Requests to improve this project. Please provide detailed error descriptions and reproduction steps when reporting issues.

## License

This project is open-sourced under the [MIT License](https://www.google.com/search?q=LICENSE).
