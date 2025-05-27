# Android 16 终端 Debian GUI 访问工具

![Bash](https://img.shields.io/badge/Shell-Bash-green) 
![Debian](https://img.shields.io/badge/OS-Debian%2012-red) 
![VNC](https://img.shields.io/badge/Protocol-VNC-blue)
![Platform](https://img.shields.io/badge/Platform-Android%2016-lightgrey)

## 🚀 功能简介

本脚本专为在 Android 16 系统自带的终端环境下运行设计，可快速配置 Debian 12 系统的图形界面访问功能。

```bash
# 典型使用流程
1. 安卓终端执行本脚本
2. PC端执行: adb forward tcp:5901 tcp:5901
3. VNC客户端连接 localhost:5901
