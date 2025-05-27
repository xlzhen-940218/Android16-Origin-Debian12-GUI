# Android 16 终端 Debian GUI 访问工具

![Bash](https://img.shields.io/badge/Shell-Bash-green) ![Debian](https://img.shields.io/badge/OS-Debian%2012-red) ![VNC](https://img.shields.io/badge/Protocol-VNC-blue)

## 功能简介

本脚本专为在 Android 16 系统自带的终端环境下运行设计，可快速配置 Debian 12 系统的图形界面访问功能。配置完成后，您可以通过以下步骤在 PC 端访问 Android 终端内的原生 Debian 12 GUI 界面：

1. 在 Android 终端运行本脚本完成配置
2. 在 PC 端执行 `adb forward tcp:5901 tcp:5901` 端口转发
3. 使用任意 VNC 客户端软件连接 `localhost:5901`

## 主要特性

- **一键式配置**：自动化完成所有必要组件的安装和配置
- **SSH 访问**：配置 SSH 服务并修改默认端口为 10022
- **图形界面支持**：安装完整的桌面环境和 VNC 服务器
- **智能检测**：自动跳过已完成的配置步骤
- **UTF-8 语言环境检测**：避免重复设置已配置的语言环境
- **详细日志输出**：彩色标记不同级别的操作信息

## 使用说明

### 前置条件

- Android 16 系统终端环境
- 已安装并配置好 Debian 12 系统
- 具有 root 权限或 sudo 权限

### 安装步骤

1. 将脚本保存到您的 Android 终端设备，例如保存为 `setup_debian_gui.sh`
2. 赋予脚本执行权限：
   ```bash
   chmod +x setup_debian_gui.sh
   ```
3. 运行脚本：
   ```bash
   ./setup_debian_gui.sh
   ```

### PC 端连接步骤

1. 确保 Android 设备已通过 USB 连接到 PC
2. 在 PC 端执行端口转发：
   ```bash
   adb forward tcp:5901 tcp:5901
   ```
3. 打开 VNC 客户端，连接地址填写：
   ```
   localhost:5901
   ```
4. 输入您在脚本运行过程中设置的 VNC 密码

## 脚本功能详解

脚本将依次执行以下配置：

1. **系统更新**：更新软件包列表
2. **SSH 服务配置**：
   - 安装 OpenSSH 服务器
   - 修改 SSH 端口为 10022
   - 启用密码认证
3. **语言环境设置**：
   - 安装 locales 包
   - 仅当未检测到 UTF-8 语言环境时提示用户设置
4. **桌面环境安装**：
   - 安装 tasksel 工具
   - 安装完整桌面环境
5. **VNC 服务器配置**：
   - 安装 TigerVNC 服务器
   - 设置 VNC 密码（首次运行）
   - 配置 VNC 服务器参数
   - 设置 VNC 服务开机自启

## 注意事项

1. 首次运行 VNC 服务器时会提示设置密码，请牢记您设置的密码
2. 脚本运行过程中可能需要多次确认操作，请按照提示操作
3. 建议在稳定的网络环境下运行，以确保软件包下载顺利
4. 配置完成后，您可以通过以下命令管理 VNC 服务：
   - 启动服务：`sudo systemctl start tigervncserver@:1.service`
   - 停止服务：`sudo systemctl stop tigervncserver@:1.service`
   - 查看状态：`sudo systemctl status tigervncserver@:1.service`

## 贡献与反馈

欢迎提交 Issue 或 Pull Request 来改进本项目。如果您在使用过程中遇到任何问题，请提供详细的错误描述和重现步骤。

## 许可证

本项目采用 [MIT License](LICENSE) 开源。
