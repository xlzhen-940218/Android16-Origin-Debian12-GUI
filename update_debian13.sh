#!/bin/bash

# ====================================================================================
# Debian 12 (bookworm) to Debian 13 (trixie) 升级脚本
#
# 注意:
# 1. 该脚本假定您从Debian 12升级到Debian 13。如果您在Debian 11上，请先升级到Debian 12。
# 2. 确保在运行此脚本前已备份重要数据。
# 3. 升级过程中可能会提示您选择配置，通常选择“保留现有配置”和“重启服务”。
# 4. 该脚本只处理操作系统本身，应用程序可能需要额外的手动步骤。
# ====================================================================================

# 检查当前Debian版本
if ! grep -q "bookworm" /etc/os-release; then
    echo "错误: 当前系统不是 Debian 12 (bookworm)。此脚本仅用于从 Debian 12 升级。"
    exit 1
fi

echo "🚀 开始将 Debian 12 (bookworm) 升级到 Debian 13 (trixie)..."

# 步骤 1: 检查磁盘空间
echo "--- 1. 检查可用磁盘空间 ---"
df -h
echo "建议至少有 5GiB 的可用空间。如果空间不足，请使用 'sudo apt clean' 和 'sudo apt autoremove' 来清理。"
read -p "按 Enter 键继续..."

# 步骤 2: 更新当前系统
echo "--- 2. 更新当前发行版 ---"
sudo apt update && sudo apt full-upgrade -y

# 检查是否需要重启（例如，如果内核已更新）
if [ -f /var/run/reboot-required ]; then
    echo "--- 检测到需要重启。系统将在10秒后重启... ---"
    sudo reboot
    # 脚本将在重启后重新启动，继续执行
    # 如果脚本没有在重启后自动继续，您需要手动再次运行它
    exit 0
fi

# 步骤 3: 修改 /etc/apt/sources.list
echo "--- 3. 更改主仓库为 trixie ---"
sudo sed -i 's/bookworm/trixie/g' /etc/apt/sources.list
echo "仓库已从 'bookworm' 更改为 'trixie'。"

# 步骤 4: 检查并修改第三方仓库
echo "--- 4. 检查并修改第三方仓库 ---"
if [ -d "/etc/apt/sources.list.d" ]; then
    echo "正在更改所有第三方仓库中的 'bookworm' 为 'trixie'..."
    find /etc/apt/sources.list.d -type f -exec sed -i 's/bookworm/trixie/g' {} \;
    echo "第三方仓库修改完成。"
else
    echo "没有找到第三方仓库目录 /etc/apt/sources.list.d。"
fi

# 步骤 5: 更新仓库列表
echo "--- 5. 重新加载仓库列表 ---"
sudo apt update

# 检查并处理 'non-free' 和 'non-free-firmware'
if grep -q "non-free" /etc/apt/sources.list && ! grep -q "non-free-firmware" /etc/apt/sources.list; then
    echo "--- ❗ 警告: 检测到 'non-free' 但没有 'non-free-firmware'。---"
    echo "'non-free' 已在 Debian 12 之后拆分。建议您添加 'non-free-firmware'。"
    echo "您可以手动编辑 /etc/apt/sources.list 或在升级后处理。"
fi

# 步骤 6: 安装 screen (可选)
echo "--- 6. 安装 screen (可选，建议在SSH会话中运行) ---"
read -p "是否安装并使用 screen 来防止连接中断？ (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo apt install -y screen
    echo "请在 screen 中运行此脚本的剩余部分，例如：'screen -S upgrade_session ./upgrade.sh'"
    echo "现在退出，请手动重新运行脚本。"
    exit 0
fi

# 步骤 7: 执行升级
echo "--- 7. 执行完整的发行版升级 ---"
echo "请在升级过程中对提示保持关注。建议选择 '保留现有配置文件'。"
sudo apt full-upgrade -y

# 步骤 8: 清理旧的包
echo "--- 8. 清理旧的包 ---"
sudo apt autoremove -y && sudo apt clean

# 步骤 9: 现代化 sources.list (可选但推荐)
echo "--- 9. 现代化 sources.list (可选但推荐) ---"
read -p "是否将 sources.list 转换为 deb822 格式？ (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo apt modernize-sources
    echo "sources.list 已更新为 deb822 格式。"
fi

# 步骤 10: 重启以完成升级
echo "--- 10. 升级完成。系统将在10秒后重启以应用所有更改。---"
sudo reboot
