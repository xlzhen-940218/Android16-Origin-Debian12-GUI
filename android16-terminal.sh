#!/bin/bash

# 设置默认语言
LANG="cn"

# 用户选择语言
echo "请选择语言 / Please select language:"
echo "1. 中文"
echo "2. English"
read -p "输入数字 / Enter number (1/2): " lang_choice
case $lang_choice in
    2) LANG="en" ;;
    *) LANG="cn" ;;
esac

# ===== 新增密码设置选项 =====
if [ "$LANG" = "cn" ]; then
    read -p "是否为 droid 用户设置密码？(y/n): " set_pwd
else
    read -p "Set password for droid user? (y/n): " set_pwd
fi

if [ "$set_pwd" = "y" ] || [ "$set_pwd" = "Y" ]; then
    sudo passwd droid
fi
# ===== 新增部分结束 =====

# 多语言定义
declare -A messages
messages=(
    # 通用提示
    ["press_enter_cn"]="按回车键继续..."
    ["press_enter_en"]="Press Enter to continue..."
    ["install_success_cn"]="安装 %s 成功"
    ["install_success_en"]="Successfully installed %s"
    ["install_fail_cn"]="安装 %s 失败"
    ["install_fail_en"]="Failed to install %s"

    # 功能相关
    ["set_password_cn"]="请设置droid的密码..."
    ["set_password_en"]="Setting password for droid..."
    ["update_pkg_cn"]="正在更新软件包列表..."
    ["update_pkg_en"]="Updating package list..."
    ["modify_ssh_cn"]="正在修改sshd_config..."
    ["modify_ssh_en"]="Modifying sshd_config..."
    ["port_prompt_cn"]="请到终端设置开启10022端口"
    ["port_prompt_en"]="Please open port 10022 in your terminal"
    ["vnc_port_prompt_cn"]="请到终端设置开启5901端口"
    ["vnc_port_prompt_en"]="Please open port 5901 in your terminal"
    ["locale_prompt_cn"]="请设置您的国家/地区和语言(推荐选择带UTF-8的选项)"
    ["locale_prompt_en"]="Please configure your locale (recommend UTF-8 options)"
    ["complete_cn"]="所有配置已完成！"
    ["complete_en"]="All configurations completed!"
    
    # check_utf8_locale
    ["locale_detected_cn"]="检测到已设置UTF-8语言环境:"
    ["locale_detected_en"]="UTF-8 locale detected:"
    ["locale_notset_cn"]="未检测到UTF-8语言环境设置"
    ["locale_notset_en"]="No UTF-8 locale detected"
    ["locale_skipped_cn"]="跳过语言环境设置，已配置UTF-8语言环境"
    ["locale_skipped_en"]="Skipping locale setup, UTF-8 already configured"
)

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 获取本地化信息
function lang() {
    local key="${1}_${LANG}"
    printf "${messages[$key]}"
}

# 信息显示函数
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
    read -r -p "$(lang press_enter)"
}

# 安装软件包函数
function install_package() {
    info "$(printf "$(lang install_success)" "$1")"
    if ! sudo apt install -y "$1"; then
        error "$(printf "$(lang install_fail)" "$1")"
        exit 1
    fi
}

# 主程序开始
# ===== 已移除原有的密码判断逻辑 =====

info "$(lang update_pkg)"
sudo apt update -y || {
    error "$(lang update_fail)"
    exit 1
}

sudo apt upgrade -y || {
    error "$(lang update_fail)"
    exit 1
}

install_package "openssh-server"

info "$(lang modify_ssh)"
sudo sed -i \
    -e 's/^#\s*Port 22/Port 10022/' \
    -e 's/^#\s*PasswordAuthentication yes/PasswordAuthentication yes/' \
    -e 's/^PasswordAuthentication no/#PasswordAuthentication no/' \
    /etc/ssh/sshd_config || {
    error "SSH configuration failed"
    exit 1
}

prompt_continue "$(lang port_prompt)"

# install_package "locales"

# 检测安装的语言
function check_utf8_locale() {
    # 获取当前的 LC_ALL 和 LANG 设置
    lc_all=$(locale 2>/dev/null | awk -F= '/^LC_ALL=/ {print $2}' | tr -d '"')
    lang=$(locale 2>/dev/null | awk -F= '/^LANG=/ {print $2}' | tr -d '"')

    # 确定当前生效的区域设置
    if [ -n "$lc_all" ]; then
        echo "$lc_all"
    else
        echo "$lang"
    fi
}

current_locale=$(check_utf8_locale)  # 调用函数并获取返回值

echo "current locale:"
echo "$current_locale"

if [ "$current_locale" = "zh_CN.UTF-8" ]; then
    echo "zh_CN.UTF-8 already set"
else
    echo "zh_CN.UTF-8 not set"
    sudo apt install locales -y
    export LANGUAGE=zh_CN.UTF-8
    export LC_ALL=zh_CN.UTF-8
    export LANG=zh_CN.UTF-8
    export LC_CTYPE=zh_CN.UTF-8
fi

install_package "tasksel"
info "Installing desktop environment..."
sudo tasksel install kde-desktop || {
    error "Desktop installation failed"
    exit 1
}

# 解决最新系统自带vnc无法登录问题
echo -e "[Autologin]\nUser=droid\nSession=plasma.desktop" | sudo tee /etc/sddm.conf

install_package "tigervnc-standalone-server"
install_package "tigervnc-common"

if [ ! -f ~/.vnc/passwd ]; then
    info "Configuring VNC password..."
    vncserver || {
        error "VNC password setup failed"
        exit 1
    }
    vncserver -kill :1
    info "VNC password configured"
else
    info "VNC password already configured"
fi

info "Configuring VNC server..."
mkdir -p ~/.vnc

cat > ~/.vnc/config << 'EOF'
session=plasma-desktop
geometry=1920x1080
localhost=no
alwaysshared
EOF

echo ":2=droid" | sudo tee /etc/tigervnc/vncserver.users >/dev/null

sudo systemctl start tigervncserver@:2.service || {
    error "Failed to start VNC service"
    exit 1
}
sudo systemctl enable tigervncserver@:2.service || {
    error "Failed to enable VNC service"
    exit 1
}

prompt_continue "$(lang vnc_port_prompt)"

info "$(lang complete)"

info "install pinyin input method"
sudo apt install ibus ibus-pinyin -y
info "configure ibus pinyin"
im-config -n ibus
