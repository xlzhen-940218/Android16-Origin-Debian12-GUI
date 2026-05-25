## AD FocuSee [Record Your Screen. Get Polished Videos Automatically.](https://focusee.imobie.com?ad=github-xlzhen)

# Android 16 终端 Debian GUI 访问工具

![Bash](https://img.shields.io/badge/Shell-Bash-green) ![Debian](https://img.shields.io/badge/OS-Debian%2012%20|%2013-red) ![VNC](https://img.shields.io/badge/Protocol-VNC-blue)

**English Documentation**: [README.md](README.md)

---

## 📖 功能简介

本脚本专为在 Android 16 系统自带的 Linux 虚拟机/终端环境下运行设计。它能全自动化地为 **Debian 12 (Bookworm)** 和 **Debian 13 (Trixie)** 配置完整的图形界面（GUI），并深度解决了 Android 宿主机与 Debian 之间的底层系统兼容性问题。

配置完成后，您可以在手机本地或通过 PC 大屏无缝访问原生的 Debian 桌面环境。

## ✨ 主要特性

- **双语交互界面**：脚本执行过程中全面支持中文/英文 UI 切换。
- **Debian 13 & Wayland 兼容适配**：自动识别并强制 VNC 使用 X11 会话，彻底解决 Debian 13 默认 Wayland 导致的黑屏和闪退问题。
- **Android 虚拟机深度集成**：
  - 植入 Systemd 网络桥接等待补丁，解决 VNC/SSH 启动过快导致的端口绑定失效和偶发性断连。
  - 自动将 Android 宿主机的 `/mnt/shared` 共享目录映射为桌面独立磁盘，方便跨系统文件管理。
- **全局中文环境与输入法修复**：突破虚拟机强制 `C.UTF-8` 的限制，自动配置全局中文 locale，安装 CJK 字体防方块字，并集成新一代 **Fcitx5** 中文拼音输入法。
- **一键常用软件套件 (可选)**：提供一键安装 Chromium 浏览器、LibreOffice 办公套件、VLC 播放器、GIMP 图像编辑器以及完整系统工具链（htop, git, curl, unzip 等）。
- **安全远程访问**：自动配置 SSH 服务（强制 IPv4 并在非标端口 `10022` 运行）与 TigerVNC 服务器（端口 `5901`）。

---

## 🚀 使用说明

### 前置条件

- Android 16 系统终端 / Linux 虚拟机环境。
- **请使用普通用户账户运行脚本**（切勿直接使用 `root` 运行，脚本会在需要时自动请求 `sudo` 权限）。

### 安装步骤

1. 将脚本保存到您的 Android 终端设备，例如保存为 `android16-terminal.sh`。
2. 赋予脚本执行权限：
```bash
   chmod +x android16-terminal.sh

```

3. 运行脚本：

```bash
   ./android16-terminal.sh

```

4. 根据屏幕上的交互提示，选择界面语言、偏好的桌面环境（支持 KDE, GNOME, XFCE 等 8 种桌面）、设置 VNC 密码，并选择是否安装附加软件套件。

---

## 💻 推荐连接方式

### 方式一：Windows 电脑大屏访问 (推荐，通过 ADB 转发)

1. 确保手机已通过 USB 连接电脑，并在 Android 开发者选项中开启 **USB 调试**。
2. 在 Windows 终端 (CMD 或 PowerShell) 执行端口转发命令：

```bash
   adb forward tcp:5901 tcp:5901

```

3. 在电脑端打开任意 VNC 客户端（如 TigerVNC Viewer），连接地址填写：

```text
   127.0.0.1:5901

```

> **💡 提示**：如果需要通过电脑 SSH 连接终端，可执行 `adb forward tcp:10022 tcp:10022`，然后在电脑端通过 `ssh username@127.0.0.1 -p 10022` 进行登录。

### 方式二：手机端直连访问

1. 在 Android 手机上下载并安装 VNC 客户端 App（强烈推荐 **AVNC**）。
2. 在 App 中新建连接，地址填写 `127.0.0.1`，端口填写 `5901`。
3. 连接并输入您在脚本运行过程中设置的 VNC 密码即可进入桌面。

---

## 🛠️ 常见问题与排障

* **❓ VNC 突然连不上、黑屏或一直超时？**
* **原因**：这通常是 Android 系统极其激进的后台电池优化导致的（进程被挂起或网络套接字被冻结）。
* **解决方案**：请前往 Android 系统设置 -> 找到该终端虚拟机 App -> 将【电池优化】改为【无限制 (Unrestricted)】。如果当前已断连，请在多任务卡片界面彻底划掉关闭终端 App，重新打开即可恢复。
* **❓ 桌面无法输入中文 / Fcitx5 没出来？**
* **原因**：输入法框架在初次安装后需要重启桌面会话才能注入环境变量。
* **解决方案**：彻底重启终端 App，或者在命令行执行 `vncserver -kill :1 && vncserver :1` 重启 VNC 服务。
* **❓ 桌面的 "Android文件" 共享目录是空的，或者提示权限不足？**
* **原因**：由于 Android 虚拟机的 Root Squash 机制或权限缺失导致。
* **解决方案**：请确保您的终端 App 在系统设置中拥有【访问所有文件 / 存储】的权限。如果权限正常但依然无法挂载，请重启手机以重置 Android 底层的 VirtioFS 挂载状态。

---

## ⚙️ 脚本功能底层流转

脚本将依次自动化执行以下核心流程：

1. **环境准备**：更新 apt 缓存库，写入本机 hostname 映射防止解析卡死。
2. **语言锁定**：静默覆盖 `/etc/default/locale` 和 `~/.bashrc`，锁定 UTF-8 环境。
3. **网络补丁注入**：向 Systemd 写入 Drop-in 规则，强制 SSH 和 VNC 监听 IPv4 并等待网络彻底就绪。
4. **组件下发**：按需拉取 tasksel 部署核心桌面，补齐 `dbus-x11` 防止桌面闪退。
5. **用户态映射**：生成 `~/.vnc/config` 强制 X11 会话，修改 GTK 侧边栏书签以注入 Android 存储。

---

## ⚠️ 注意事项

1. 建议在稳定的网络环境下运行，以确保大型桌面包下载顺利。
2. 配置完成后，您可以通过以下命令手动管理 VNC 服务：

* 启动服务：`sudo systemctl start tigervncserver@:1.service`
* 停止服务：`sudo systemctl stop tigervncserver@:1.service`
* 查看状态：`sudo systemctl status tigervncserver@:1.service`

---

## 🤝 贡献与反馈

欢迎提交 Issue 或 Pull Request 来改进本项目。如果您在使用过程中遇到任何问题，请提供详细的错误描述和重现步骤。

## 📜 许可证

本项目采用 [MIT License](https://www.google.com/search?q=LICENSE) 开源。
