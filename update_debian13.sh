#!/bin/bash

# ==============================================================================
#
#                            Debian 12 -> 13 升级脚本
#
#   本脚本旨在将 Debian 12 (Bookworm) 系统升级到 Debian 13 (Trixie)。
#
#   作者：Gemini (由 Google 强力驱动)
#   版本：1.0
#   最后更新日期：2025年7月16日
#
# ==============================================================================

# --- 安全检查与用户确认 ---

echo "####################################################################"
echo "#                                                                  #"
echo "#                    Debian 12 -> 13 (Trixie) 升级                 #"
echo "#                                                                  #"
echo "####################################################################"
echo
echo "警告：这是一个重大的系统升级，存在潜在风险，可能导致系统不稳定或数据丢失。"
echo "在继续之前，请务必完成以下操作："
echo
echo "  1. [强烈建议] **备份所有重要数据**！"
echo "  2. [强烈建议] **确保您的系统当前已是最新状态 (sudo apt update && sudo apt upgrade)**。"
echo "  3. [建议]     **在稳定的网络环境下运行此脚本**。"
echo "  4. [建议]     **移除所有非官方或第三方的软件源 (PPA)**。"
echo

read -p "您是否已阅读以上警告并希望继续升级？(输入 'yes' 继续): " confirmation
if [ "$confirmation" != "yes" ]; then
    echo "操作已取消。"
    exit 1
fi

echo "好的，准备开始升级..."
sleep 2

# --- 步骤 1: 替换软件源 ---
echo "[步骤 1/3] 正在将软件源从 'bookworm' (Debian 12) 切换到 'trixie' (Debian 13)..."

# 替换主软件源文件
sudo sed -i 's/bookworm/trixie/g' /etc/apt/sources.list

# 替换 /etc/apt/sources.list.d/ 目录下的所有软件源文件
# 使用 find 命令来确保所有相关文件都被更新
sudo find /etc/apt/sources.list.d -type f -name "*.list" -exec sed -i 's/bookworm/trixie/g' {} \;

echo "软件源切换完成！"
sleep 1

# --- 步骤 2: 更新软件源索引 ---
echo "[步骤 2/3] 正在使用新的 'trixie' 软件源更新软件包列表..."
sudo apt update
if [ $? -ne 0 ]; then
    echo "错误：'apt update' 执行失败。请检查您的网络连接或软件源配置。"
    exit 1
fi
echo "软件包列表更新成功！"
sleep 1

# --- 步骤 3: 执行系统完整升级 ---
echo "[步骤 3/3] 正在执行完整的系统升级（dist-upgrade）。这可能需要很长时间..."
echo "升级过程中，系统可能会询问您关于配置文件替换的问题，请根据您的需求进行选择。"

sudo apt dist-upgrade --autoremove -y
if [ $? -ne 0 ]; then
    echo "错误：'dist-upgrade' 过程中出现问题。请检查上面的错误信息进行排查。"
    exit 1
fi

# --- 完成 ---
echo
echo "####################################################################"
echo "#                                                                  #"
echo "#                       恭喜！升级流程已完成                      #"
echo "#                                                                  #"
echo "####################################################################"
echo
echo "系统已成功升级到 Debian 13 (Trixie)。"
echo "为了应用所有更改（特别是新的内核），强烈建议您现在重启计算机。"
echo
read -p "是否立即重启？(输入 'yes' 重启): " reboot_confirmation
if [ "$reboot_confirmation" == "yes" ]; then
    echo "正在重启..."
    sudo reboot
else
    echo "请记得稍后手动重启。"
fi

exit 0
