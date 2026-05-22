#!/bin/bash

# ==============================================================================
# 脚本名称: Debian 桌面环境与远程访问一键安装脚本 (Android 16 虚拟机深度适配版)
# 脚本功能: 自动化安装选择的桌面环境并配置好 SSH 和 TigerVNC 远程访问。
# 适用系统: Debian 12 (Bookworm) / Debian 13 (Trixie) / Android Linux VM
# 特点:
#   - 修复 Android 虚拟机中 VNC 解析卡死、黑屏 (补充 dbus-x11 和 hosts 修复)。
#   - 修复 Debian 13 默认 Wayland 导致 VNC 黑屏的问题 (强制 X11 会话)。
#   - 修复 C.UTF-8 导致中文无法全局生效的问题，自动安装 CJK 字体并锁定环境变量。
#   - 自动映射 Android 共享目录 (/mnt/shared) 到桌面和文件管理器侧边栏。
#   - 输入法框架升级为 Fcitx5。
# ==============================================================================

# --- 全局变量和初始化 ---
LANG_CHOICE="cn"
TARGET_USER=$(whoami)

# 检查是否以 root 运行
if [ "$(id -u)" -eq 0 ]; then
  echo -e "\033[0;31m[ERROR]\033[0m 请不要以 root 用户身份运行此脚本。请使用一个普通用户账户运行，脚本会在需要时请求 sudo 权限。"
  exit 1
fi

# 检查 sudo 是否安装
if ! command -v sudo &> /dev/null; then
  echo -e "\033[0;31m[ERROR]\033[0m 未找到 'sudo' 命令。请先以 root 身份执行 'apt install sudo'，并将当前用户加入 sudo 组。"
  exit 1
fi

# --- 颜色定义 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- 多语言消息定义 ---
declare -A messages
messages=(
    # --- 通用 ---
    ["press_enter_cn"]="按回车键继续..."
    ["invalid_option_cn"]="无效的选项，请重试。"
    ["operation_cancelled_cn"]="操作已取消。"

    # --- 信息 ---
    ["install_success_cn"]="成功安装 %s"
    ["config_success_cn"]="成功配置 %s"
    ["install_fail_cn"]="安装 %s 失败"
    ["command_fail_cn"]="命令执行失败: %s"
    
    # --- 流程 ---
    ["welcome_banner_cn"]="欢迎使用 Debian 桌面环境一键安装脚本 (Android VM 特化版)"
    ["set_password_prompt_cn"]="是否为用户 '$TARGET_USER' 设置或更改登录密码？(y/n): "
    ["desktop_select_cn"]="选择您想安装的桌面环境"
    ["enter_desktop_num_cn"]="请输入您想安装的桌面环境编号: "
    ["confirm_banner_cn"]="安装确认"
    ["confirm_intro_cn"]="将在系统上执行以下操作:"
    ["confirm_user_cn"]="  - 用户: '$TARGET_USER'"
    ["confirm_desktop_cn"]="  - 安装桌面: "
    ["confirm_ssh_cn"]="  - 配置 SSH 服务 (端口 10022)"
    ["confirm_vnc_cn"]="  - 配置 VNC 服务 (端口 5901)"
    ["confirm_proceed_cn"]="是否继续? (y/n): "

    ["update_pkg_cn"]="正在更新软件包列表..."
    ["upgrade_pkg_cn"]="正在升级已安装的软件包..."
    ["ssh_modify_cn"]="正在配置 SSH 服务器..."
    ["ssh_port_prompt_cn"]="SSH 端口已配置为 10022。"
    ["vnc_port_prompt_cn"]="VNC 服务已配置在 5901 端口。"
    
    # 语言和字体相关
    ["locale_check_cn"]="正在强制配置系统语言环境和安装字体..."
    ["desktop_install_cn"]="正在安装 %s 桌面环境，这可能需要一些时间..."
    ["vnc_passwd_prompt_cn"]="接下来，请为您 VNC 会话设置一个密码 (至少6位)。"
    ["vnc_config_cn"]="正在配置 TigerVNC 并修复 Android VM 环境依赖..."
    
    ["input_method_prompt_cn"]="是否安装中文拼音输入法 (推荐新一代的 Fcitx5)? (y/n): "
    ["ime_install_banner_cn"]="正在安装中文输入法 (Fcitx5)..."
    ["ime_config_done_cn"]="输入法配置完成，重启桌面或 VNC 服务后即可生效。"
    
    ["common_apps_desc_cn"]="可选软件套件包含：\n  - 网页浏览器: Chromium\n  - 办公套件: LibreOffice (含中文语言包)\n  - 多媒体与图像: VLC 播放器, GIMP 图像编辑器\n  - 实用工具: Flameshot (截图), p7zip/unzip (解压缩), Remmina (远程桌面客户端)\n  - 系统与网络: htop, curl, wget, git"
    ["common_apps_prompt_cn"]="是否安装上述常用桌面及系统软件套件? (y/n): "
    ["apps_install_banner_cn"]="正在安装常用软件套件..."

    # Android 共享目录
    ["android_share_banner_cn"]="正在挂载 Android 共享目录..."
    ["android_share_done_cn"]="Android 共享目录已映射为独立磁盘，可在文件管理器侧边栏或桌面访问。"

    ["final_summary_cn"]="🎉 所有配置已完成！"
    ["final_info_cn"]="您现在可以使用以下信息进行远程连接："
    ["final_ssh_header_cn"]="  ${YELLOW}SSH (命令行):${NC}"
    ["final_vnc_header_cn"]="  ${YELLOW}VNC (图形桌面):${NC}"
    ["final_vnc_addr_cn"]="    VNC 服务器地址: %s:1"
    ["final_vnc_alt_cn"]="    (或者在 VNC 客户端中输入 localhost 或手机的内网 IP，并指定端口 5901)"
)

# --- 辅助函数 ---
function lang() { local key="${1}_${LANG_CHOICE}"; printf -- "${messages[$key]}"; }
function info() { echo -e "${GREEN}[INFO]${NC} $1"; }
function warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
function error() { echo -e "${RED}[ERROR]${NC} $1"; }
function banner() { echo -e "${BLUE}============================================================${NC}\n${BLUE}$1${NC}\n${BLUE}============================================================${NC}"; }
function prompt_continue() { echo ""; read -r -p "$(lang press_enter)"; }
function run_cmd() { if ! "$@"; then error "$(printf "$(lang command_fail)" "$*")"; exit 1; fi; }
function install_package() { local pkg_name=$1; if ! sudo apt install -y "$pkg_name"; then error "$(printf "$(lang install_fail)" "$pkg_name")"; exit 1; fi; info "$(printf "$(lang install_success)" "$pkg_name")"; }

# --- 主要功能函数 ---

function user_selections() {
    clear
    banner "$(lang welcome_banner)"
    
    # 默认强制中文，不再询问，直接锁定。因为主要就是针对中文环境的问题修复。
    LANG_CHOICE="cn"
    
    read -p "$(lang set_password_prompt)" set_pwd
    if [[ "$set_pwd" =~ ^[Yy]$ ]]; then sudo passwd $TARGET_USER; fi

    banner "$(lang desktop_select)"
    echo "1. KDE Plasma"; echo "2. GNOME"; echo "3. XFCE"; echo "4. MATE"; echo "5. Cinnamon"; echo "6. LXQt"; echo "7. LXDE"; echo "8. GNOME Flashback"

    while true; do
        read -p "$(lang enter_desktop_num)" desktop_choice
        case $desktop_choice in
            1) DESKTOP_NAME="KDE Plasma"; TASKSEL_TASK="kde-desktop"; VNC_SESSION="plasmax11"; VNC_FALLBACK="plasma"; break ;;
            2) DESKTOP_NAME="GNOME"; TASKSEL_TASK="gnome-desktop"; VNC_SESSION="gnome-xorg"; VNC_FALLBACK="gnome"; break ;;
            3) DESKTOP_NAME="XFCE"; TASKSEL_TASK="xfce-desktop"; VNC_SESSION="xfce"; VNC_FALLBACK=""; break ;;
            4) DESKTOP_NAME="MATE"; TASKSEL_TASK="mate-desktop"; VNC_SESSION="mate"; VNC_FALLBACK=""; break ;;
            5) DESKTOP_NAME="Cinnamon"; TASKSEL_TASK="cinnamon-desktop"; VNC_SESSION="cinnamon"; VNC_FALLBACK="cinnamon2d"; break ;;
            6) DESKTOP_NAME="LXQt"; TASKSEL_TASK="lxqt-desktop"; VNC_SESSION="lxqt"; VNC_FALLBACK=""; break ;;
            7) DESKTOP_NAME="LXDE"; TASKSEL_TASK="lxde-desktop"; VNC_SESSION="LXDE"; VNC_FALLBACK="lxde"; break ;;
            8) DESKTOP_NAME="GNOME Flashback"; TASKSEL_TASK="gnome-flashback-desktop"; VNC_SESSION="gnome-flashback-metacity"; VNC_FALLBACK=""; break ;;
            *) error "$(lang invalid_option)" ;;
        esac
    done

    clear
    banner "$(lang confirm_banner)"
    echo "$(lang confirm_intro)"
    printf "$(lang confirm_user)\n"
    printf "$(lang confirm_desktop) '$DESKTOP_NAME'\n"
    echo "$(lang confirm_ssh)"
    echo "$(lang confirm_vnc)"
    read -p "$(lang confirm_proceed)" confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then info "$(lang operation_cancelled)"; exit 0; fi
}

function prepare_system() {
    banner "$(lang update_pkg)"; run_cmd sudo apt-get update -y
    banner "$(lang upgrade_pkg)"; run_cmd sudo apt-get upgrade -y
    
    # 修复 Android VM 常见的 hostname 解析问题，防止后面各种网络和 X11 服务卡死
    if ! grep -q "$(hostname)" /etc/hosts; then
        echo "127.0.0.1 $(hostname)" | sudo tee -a /etc/hosts > /dev/null
    fi

    # 彻底解决系统默认 C.UTF-8 导致桌面英文的问题
    banner "$(lang locale_check)"
    install_package "locales"
    
    # 解除注释并生成中文 locale
    sudo sed -i 's/^# *\(zh_CN.UTF-8 UTF-8\)/\1/' /etc/locale.gen
    sudo sed -i 's/^# *\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen
    run_cmd sudo locale-gen
    
    # 强制覆盖全局语言设置
    sudo update-locale LANG=zh_CN.UTF-8
    echo "export LANG=zh_CN.UTF-8" >> ~/.bashrc
    echo "export LC_ALL=zh_CN.UTF-8" >> ~/.bashrc
    
    # 安装中文字体防止变方块
    install_package "fonts-noto-cjk"
    install_package "fonts-wqy-zenhei"
    install_package "fonts-wqy-microhei"
}

function setup_ssh() {
    banner "$(lang ssh_modify)"; install_package "openssh-server"

    if sudo systemctl is-active --quiet ssh.socket 2>/dev/null || sudo systemctl is-enabled --quiet ssh.socket 2>/dev/null; then
        sudo systemctl disable --now ssh.socket 2>/dev/null || true
        sudo systemctl enable --now ssh.service 2>/dev/null || true
    fi

    sudo sed -i -E -e 's/^#?\s*Port\s+[0-9]+/Port 10022/' -e 's/^#?\s*PasswordAuthentication\s+no/PasswordAuthentication yes/' /etc/ssh/sshd_config
    if ! sudo grep -q "^Port 10022" /etc/ssh/sshd_config; then echo "Port 10022" | sudo tee -a /etc/ssh/sshd_config > /dev/null; fi
    if ! sudo grep -q "^PasswordAuthentication yes" /etc/ssh/sshd_config; then echo "PasswordAuthentication yes" | sudo tee -a /etc/ssh/sshd_config > /dev/null; fi
    
    if systemctl list-unit-files | grep -q "^ssh.service"; then
        run_cmd sudo systemctl restart ssh
    else
        run_cmd sudo systemctl restart sshd
    fi
    info "$(lang ssh_port_prompt)"
}

function install_desktop() {
    banner "$(printf "$(lang desktop_install)" "$DESKTOP_NAME")"
    install_package "tasksel"
    run_cmd sudo tasksel install $TASKSEL_TASK
}

function setup_vnc() {
    banner "$(lang vnc_config)"
    install_package "tigervnc-standalone-server"
    install_package "tigervnc-common"
    # Android VM 缺少该包会导致桌面环境（尤其是 XFCE 和 GNOME）启动闪退
    install_package "dbus-x11"
    
    # 修复由于 Android 系统内核权限限制导致的 socket 创建问题
    sudo mkdir -p /tmp/.X11-unix
    sudo chmod 1777 /tmp/.X11-unix

    info "$(lang vnc_passwd_prompt)"; run_cmd vncpasswd
    mkdir -p ~/.vnc
    
    ACTUAL_SESSION="$VNC_SESSION"
    if [ ! -f "/usr/share/xsessions/${VNC_SESSION}.desktop" ] && [ -n "$VNC_FALLBACK" ] && [ -f "/usr/share/xsessions/${VNC_FALLBACK}.desktop" ]; then
        ACTUAL_SESSION="$VNC_FALLBACK"
    fi

    cat > ~/.vnc/config <<- EOF
		session=$ACTUAL_SESSION
		geometry=1920x1080
		localhost=no
		alwaysshared
	EOF
    
    sudo mkdir -p /etc/tigervnc
    echo ":1=$TARGET_USER" | sudo tee /etc/tigervnc/vncserver.users >/dev/null
    
    run_cmd sudo systemctl daemon-reload
    sudo systemctl enable tigervncserver@:1.service 2>/dev/null || true
    run_cmd sudo systemctl restart tigervncserver@:1.service
    info "$(lang vnc_port_prompt)"
}

function setup_android_shared() {
    banner "$(lang android_share_banner)"
    
    install_package "xdg-user-dirs"
    xdg-user-dirs-update
    
    # 确保挂载点存在
    sudo mkdir -p /mnt/shared
    
    # 获取标准桌面路径 (因为设置了中文，这里会自动解析为 '桌面' 或 'Desktop')
    DESKTOP_DIR=$(xdg-user-dir DESKTOP 2>/dev/null)
    if [ -z "$DESKTOP_DIR" ]; then DESKTOP_DIR="$HOME/Desktop"; fi
    mkdir -p "$DESKTOP_DIR"
    
    # 1. 在桌面创建软链接
    ln -sf /mnt/shared "$DESKTOP_DIR/Android文件"
    
    # 2. 将挂载点注入 GTK 侧边栏书签，让资源管理器能像独立磁盘一样看到它
    mkdir -p ~/.config/gtk-3.0
    touch ~/.config/gtk-3.0/bookmarks
    if ! grep -q "file:///mnt/shared" ~/.config/gtk-3.0/bookmarks; then
        echo "file:///mnt/shared 📱Android_共享磁盘" >> ~/.config/gtk-3.0/bookmarks
    fi
    info "$(lang android_share_done)"
}

function optional_components() {
    read -p "$(lang input_method_prompt)" install_ime
    if [[ "$install_ime" =~ ^[Yy]$ ]]; then
        banner "$(lang ime_install_banner)"
        install_package "fcitx5"
        install_package "fcitx5-chinese-addons"
        install_package "fcitx5-frontend-gtk3"
        install_package "fcitx5-frontend-qt5"
        install_package "im-config"
        
        im-config -n fcitx5
        info "$(lang ime_config_done)"
    fi

    echo ""
    echo -e "$(lang common_apps_desc)"
    read -p "$(lang common_apps_prompt)" install_apps
    if [[ "$install_apps" =~ ^[Yy]$ ]]; then
        banner "$(lang apps_install_banner)"
        
        install_package "curl"; install_package "wget"; install_package "git"
        install_package "htop"; install_package "unzip"; install_package "p7zip-full"
        install_package "chromium"; install_package "vlc"; install_package "gimp"
        install_package "flameshot"; install_package "remmina"
        install_package "libreoffice"; install_package "libreoffice-l10n-zh-cn"
    fi
}

function final_summary() {
    IP_ADDR=$(hostname -I | awk '{print $1}')
    # Android 虚拟机中有时获取不到外网 IP，给一个回环地址防崩溃
    if [ -z "$IP_ADDR" ]; then IP_ADDR="127.0.0.1"; fi
    
    clear; banner "$(lang final_summary)"
    echo ""; echo -e "$(lang final_ssh_header)"
    echo -e "    ssh $TARGET_USER@$IP_ADDR -p 10022"
    echo ""; echo -e "$(lang final_vnc_header)"
    printf "    $(lang final_vnc_addr)\n" "$IP_ADDR"
    printf "    $(lang final_vnc_alt)\n"
    echo ""
}

# --- 主程序入口 ---
function main() {
    user_selections
    prepare_system
    setup_ssh
    install_desktop
    setup_vnc
    setup_android_shared
    optional_components
    final_summary
}

main
