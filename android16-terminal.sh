#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 函数定义
function info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

function warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

function error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

function prompt_continue() {
    echo -e "${YELLOW}$1${NC}"
    read -r -p "按回车键继续..."
}

# 安装软件包函数
function install_package() {
    info "正在安装 $1..."
    sudo apt install -y "$1" || {
        error "安装 $1 失败"
        exit 1
    }
}

# 检查是否已设置UTF-8语言环境
function check_utf8_locale() {
    local current_locale
    current_locale=$(locale | grep -E "LANG=|LANGUAGE=" | grep -i "utf-8")
    if [ -n "$current_locale" ]; then
        info "检测到已设置UTF-8语言环境:"
        locale | grep -E "LANG=|LANGUAGE="
        return 0
    else
        return 1
    fi
}

# 更新软件包列表
info "正在更新软件包列表..."
sudo apt update || {
    error "更新软件包列表失败"
    exit 1
}

# 开启openssh-server
install_package "openssh-server"

# 修改SSH配置
info "正在修改sshd_config..."
sudo sed -i \
    -e 's/^#\s*Port 22/Port 10022/' \
    -e 's/^#\s*PasswordAuthentication yes/PasswordAuthentication yes/' \
    -e 's/^PasswordAuthentication no/#PasswordAuthentication no/' \
    /etc/ssh/sshd_config || {
    error "修改sshd_config失败"
    exit 1
}

prompt_continue "请到终端设置开启10022端口"

# 安装本地化支持
install_package "locales"

# 只有在未设置UTF-8语言环境时才提示用户设置
if ! check_utf8_locale; then
    warn "未检测到UTF-8语言环境设置"
    info "请设置您的国家/地区和语言(推荐选择带UTF-8的选项)"
    sudo dpkg-reconfigure locales
else
    info "跳过语言环境设置，已配置UTF-8语言环境"
fi

# 安装tasksel和桌面环境
install_package "tasksel"
info "正在安装桌面环境..."
sudo tasksel install desktop || {
    error "安装桌面环境失败"
    exit 1
}

# 安装VNC服务器
install_package "tigervnc-standalone-server"
install_package "tigervnc-common"

# 配置VNC密码
if [ ! -f ~/.vnc/passwd ]; then
    info "未检测到VNC密码配置，开始设置..."
    vncserver || {
        error "VNC密码设置失败"
        exit 1
    }
    # 第一次运行vncserver会提示设置密码
    vncserver -kill :1  # 杀死临时创建的服务器
    info "VNC密码设置完成"
else
    info "检测到已配置VNC密码，跳过设置"
fi

# 配置VNC服务器
info "正在配置VNC服务器..."
mkdir -p ~/.vnc

cat > ~/.vnc/config << 'EOF'
session=desktop
geometry=1280x720
localhost=no
alwaysshared
EOF

echo ":1=droid" | sudo tee /etc/tigervnc/vncserver.users >/dev/null

sudo systemctl start tigervncserver@:1.service || {
    error "启动VNC服务失败"
    exit 1
}
sudo systemctl enable tigervncserver@:1.service || {
    error "设置VNC服务开机自启失败"
    exit 1
}

prompt_continue "请到终端设置开启5901端口"

info "所有配置已完成！"