# 1. 安装 ADB 和平台工具
winget install --id Google.PlatformTools --source winget --accept-package-agreements --accept-source-agreements

# 2. ADB 端口转发
Write-Host "正在进行 ADB 端口转发..."
# 使用 ping 命令来判断 ADB 是否可用，并等待设备连接。
# 在执行 ADB 转发之前，请确保你的 Android 设备已经通过 USB 连接到电脑并开启了 USB 调试模式。
# 这个脚本假设 ADB 已经能正常工作，如果没有，你可能需要手动进行一次 `adb devices` 命令来授权。
try {
    adb forward tcp:5901 tcp:5901
    Write-Host "端口转发成功：5901 -> 5901"
} catch {
    Write-Error "ADB 端口转发失败。请确保 ADB 环境变量已配置，且设备已连接并授权。"
    # 如果端口转发失败，可以选择退出脚本
    # exit
}

# 3. 安装 TigerVNC Viewer
winget install --id TigerVNC.TigerVNC --source winget --accept-package-agreements --accept-source-agreements

# 4. 将 TigerVNC 目录添加到环境变量（仅在当前会话生效）
$env:Path += ";C:\Program Files\TigerVNC\"

# 5. 运行 VNC Viewer
Write-Host "正在启动 VNC Viewer..."
# 在运行前，请确保你的目标设备上已经运行了 VNC 服务器，并且监听端口为 5901。
# 脚本会等待用户按任意键后再启动 VNC Viewer，以便用户有时间检查或准备。
Read-Host "请确保你的 Android 设备上 VNC 服务器已运行，并按任意键启动 VNC Viewer..."
vncviewer.exe 127.0.0.1::5901

Write-Host "脚本执行完毕。"