#!/bin/bash

# 美化安装脚本
# 功能：自动安装Chromium、wget、Clash Verge、VS Code和Bilibili客户端

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 分隔线函数
print_separator() {
    echo -e "${BLUE}=============================================${NC}"
}

# 检查命令是否成功执行
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ 成功${NC}"
    else
        echo -e "${RED}✗ 失败${NC}"
        exit 1
    fi
}
echo -e "apt update..."
# 更新软件包列表
echo -e "\n${YELLOW}🔄 正在更新软件包列表...${NC}"
print_separator
sudo apt update
check_status

# 安装Chromium
echo -e "\n${YELLOW}🌐 正在安装Chromium浏览器...${NC}"
print_separator
sudo apt install -y chromium
check_status

# 安装wget
echo -e "\n${YELLOW}📥 正在安装wget下载工具...${NC}"
print_separator
sudo apt install -y wget
check_status

# 下载并安装Clash Verge
echo -e "\n${YELLOW}🛡️ 正在下载Clash Verge (v2.3.1 arm64)...${NC}"
print_separator
wget https://github.com/clash-verge-rev/clash-verge-rev/releases/download/v2.4.0/Clash.Verge_2.4.0_arm64.deb
check_status

echo -e "\n${YELLOW}🛠️ 正在安装Clash Verge...${NC}"
print_separator
sudo apt --fix-broken install ./Clash.Verge_2.4.0_arm64.deb
check_status

# 下载并安装VS Code
echo -e "\n${YELLOW}💻 正在下载VS Code (1.100.2 arm64)...${NC}"
print_separator
wget https://vscode.download.prss.microsoft.com/dbazure/download/stable/848b80aeb52026648a8ff9f7c45a9b0a80641e2e/code_1.100.2-1747260559_arm64.deb
check_status

echo -e "\n${YELLOW}🛠️ 正在安装VS Code...${NC}"
print_separator
sudo dpkg -i code_1.100.2-1747260559_arm64.deb
sudo apt --fix-broken install -y
check_status

# 下载并安装Bilibili客户端
echo -e "\n${YELLOW}📺 正在下载Bilibili客户端 (v1.16.5-2 arm64)...${NC}"
print_separator
wget https://github.com/msojocs/bilibili-linux/releases/download/v1.17.1-2/io.github.msojocs.bilibili_1.17.1-2_arm64.deb
check_status

echo -e "\n${YELLOW}🛠️ 正在安装Bilibili客户端...${NC}"
print_separator
sudo dpkg -i io.github.msojocs.bilibili_1.17.1-2_arm64.deb
sudo apt --fix-broken install -y
check_status

# 清理安装包
echo -e "\n${YELLOW}🧹 正在清理安装包...${NC}"
print_separator
rm -f Clash.Verge_2.3.1_arm64.deb code_1.100.2-1747260559_arm64.deb io.github.msojocs.bilibili_1.16.5-2_arm64.deb
check_status

echo -e "\n${GREEN} 安装Pi-Apps"
wget -qO- https://raw.githubusercontent.com/Botspot/pi-apps/master/install | bash

# 完成提示
echo -e "\n${GREEN}🎉 所有软件安装完成！${NC}"
echo -e "${BLUE}已安装以下软件：${NC}"
echo -e "${BLUE}• Chromium浏览器${NC}"
echo -e "${BLUE}• wget下载工具${NC}"
echo -e "${BLUE}• Clash Verge (v2.3.1)${NC}"
echo -e "${BLUE}• VS Code (1.100.2)${NC}"
echo -e "${BLUE}• Bilibili客户端 (v1.16.5-2)${NC}"
print_separator
