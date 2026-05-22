#!/bin/bash

# ==============================================================================
# 脚本名称: Debian 桌面环境与远程访问一键安装脚本 (Android VM 终极双语版)
# 脚本功能: 自动化安装选择的桌面环境并配置好 SSH 和 TigerVNC 远程访问。
# 适用系统: Debian 12 / Debian 13 / Android Linux VM
# ==============================================================================

# --- 全局变量和初始化 ---
LANG_CHOICE="cn"
TARGET_USER=$(whoami)

if [ "$(id -u)" -eq 0 ]; then
  echo -e "\033[0;31m[ERROR]\033[0m 请不要以 root 用户身份运行此脚本。请使用普通用户账户运行。"
  echo -e "\033[0;31m[ERROR]\033[0m Please do not run this script as root. Run it as a regular user."
  exit 1
fi

if ! command -v sudo &> /dev/null; then
  echo -e "\033[0;31m[ERROR]\033[0m 未找到 'sudo' 命令。请先安装 sudo 并配置当前用户。"
  echo -e "\033[0;31m[ERROR]\033[0m 'sudo' command not found. Please install it first."
  exit 1
fi

# --- 颜色定义 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- 完整的多语言消息字典 ---
declare -A messages
messages=(
    # 通用
    ["press_enter_cn"]="按回车键继续..."
    ["press_enter_en"]="Press Enter to continue..."
    ["invalid_option_cn"]="无效的选项，请重试。"
    ["invalid_option_en"]="Invalid option, please try again."
    ["operation_cancelled_cn"]="操作已取消。"
    ["operation_cancelled_en"]="Operation cancelled."
    ["install_success_cn"]="成功安装 %s"
    ["install_success_en"]="Successfully installed %s"
    ["install_fail_cn"]="安装 %s 失败"
    ["install_fail_en"]="Failed to install %s"
    ["command_fail_cn"]="命令执行失败: %s"
    ["command_fail_en"]="Command failed: %s"
    
    # 语言选择与欢迎
    ["welcome_banner_cn"]="欢迎使用 Debian 桌面环境一键安装脚本 (Android VM 特化版)"
    ["welcome_banner_en"]="Welcome to the Debian Desktop Environment Installer (Android VM Edition)"
    ["select_lang_prompt_cn"]="请选择脚本界面语言 / Please select script UI language:"
    ["select_lang_prompt_en"]="Please select script UI language / 请选择脚本界面语言:"
    ["lang_choice_cn_cn"]="1. 中文 (默认)"
    ["lang_choice_cn_en"]="1. Chinese (Default)"
    ["lang_choice_en_cn"]="2. English"
    ["lang_choice_en_en"]="2. English"
    ["enter_lang_num_cn"]="输入数字 / Enter number (1/2): "
    ["enter_lang_num_en"]="Enter number / 输入数字 (1/2): "
    
    # 用户交互
    ["set_password_prompt_cn"]="是否为用户 '$TARGET_USER' 设置或更改登录密码？(y/n): "
    ["set_password_prompt_en"]="Set or change the login password for user '$TARGET_USER'? (y/n): "
    ["desktop_select_cn"]="选择您想安装的桌面环境"
    ["desktop_select_en"]="Select the desktop environment you want to install"
    ["enter_desktop_num_cn"]="请输入您想安装的桌面环境编号: "
    ["enter_desktop_num_en"]="Please enter the number for the desktop environment: "
    
    # 确认界面
    ["confirm_banner_cn"]="安装确认"
    ["confirm_banner_en"]="Installation Confirmation"
    ["confirm_intro_cn"]="将在系统上执行以下操作:"
    ["confirm_intro_en"]="The following actions will be performed on your system:"
    ["confirm_user_cn"]="  - 用户: '$TARGET_USER'"
    ["confirm_user_en"]="  - User: '$TARGET_USER'"
    ["confirm_desktop_cn"]="  - 安装桌面: "
    ["confirm_desktop_en"]="  - Install Desktop: "
    ["confirm_ssh_cn"]="  - 配置 SSH 服务 (端口 10022，强制 IPv4 修复断连)"
    ["confirm_ssh_en"]="  - Configure SSH Service (Port 10022, IPv4 forced for stability)"
    ["confirm_vnc_cn"]="  - 配置 VNC 服务 (端口 5901，包含 Android X11 修复)"
    ["confirm_vnc_en"]="  - Configure VNC Service (Port 5901, includes Android X11 fixes)"
    ["confirm_proceed_cn"]="是否继续? (y/n): "
    ["confirm_proceed_en"]="Do you want to continue? (y/n): "

    # 系统执行
    ["update_pkg_cn"]="正在更新软件包列表..."
    ["update_pkg_en"]="Updating package list..."
    ["upgrade_pkg_cn"]="正在升级已安装的软件包..."
    ["upgrade_pkg_en"]="Upgrading installed packages..."
    ["ssh_modify_cn"]="正在配置 SSH 服务器..."
    ["ssh_modify_en"]="Configuring SSH server..."
    ["network_fix_cn"]="正在植入 Android 虚拟机网络桥接稳定性补丁..."
    ["network_fix_en"]="Applying Android VM network bridge stability patch..."
    ["locale_check_cn"]="正在强制配置系统语言环境和安装 CJK 字体..."
    ["locale_check_en"]="Forcing system locale configuration and installing CJK fonts..."
    ["desktop_install_cn"]="正在安装 %s 桌面环境，这可能需要一些时间..."
    ["desktop_install_en"]="Installing %s desktop environment, this may take a while..."
    ["vnc_passwd_prompt_cn"]="接下来，请为您 VNC 会话设置一个密码 (至少6位)。"
    ["vnc_passwd_prompt_en"]="Next, please set a password for your VNC session (at least 6 characters)."
    ["vnc_config_cn"]="正在配置 TigerVNC 并修复 Android VM 环境依赖..."
    ["vnc_config_en"]="Configuring TigerVNC and fixing Android VM dependencies..."
    
    # 附加组件
    ["android_share_banner_cn"]="正在挂载 Android 共享目录..."
    ["android_share_banner_en"]="Mounting Android shared directory..."
    ["input_method_prompt_cn"]="是否安装中文拼音输入法 (推荐 Fcitx5)? (y/n): "
    ["input_method_prompt_en"]="Install Chinese Pinyin input method (Fcitx5 recommended)? (y/n): "
    ["ime_install_banner_cn"]="正在安装中文输入法 (Fcitx5)..."
    ["ime_install_banner_en"]="Installing Chinese Input Method (Fcitx5)..."
    ["common_apps_desc_cn"]="可选软件套件包含：\n  - Chromium, LibreOffice, VLC, GIMP, htop, curl, git 等"
    ["common_apps_desc_en"]="Optional software suite includes:\n  - Chromium, LibreOffice, VLC, GIMP, htop, curl, git, etc."
    ["common_apps_prompt_cn"]="是否安装上述常用桌面及系统软件套件? (y/n): "
    ["common_apps_prompt_en"]="Install the above common desktop & system software suite? (y/n): "
    ["apps_install_banner_cn"]="正在安装常用软件套件..."
    ["apps_install_banner_en"]="Installing common software suite..."

    # 结束汇总 - 连接推荐
    ["final_summary_cn"]="🎉 所有配置已完成！"
    ["final_summary_en"]="🎉 All configurations completed!"
    ["final_client_title_cn"]="${GREEN}💻 推荐连接方式：${NC}"
    ["final_client_title_en"]="${GREEN}💻 Recommended Connection Methods:${NC}"
    ["final_client_phone_cn"]="  - 📱 ${BLUE}手机端直连:${NC} 下载安装 【AVNC】 客户端，连接地址填写 ${YELLOW}127.0.0.1${NC}，端口 ${YELLOW}5901${NC}。"
    ["final_client_phone_en"]="  - 📱 ${BLUE}On Phone:${NC} Install the [AVNC] app, connect to address ${YELLOW}127.0.0.1${NC}, port ${YELLOW}5901${NC}."
    ["final_client_pc_cn"]="  - 🖥️ ${BLUE}Windows 电脑大屏访问 (推荐，通过 ADB 转发):${NC}"
    ["final_client_pc_en"]="  - 🖥️ ${BLUE}On Windows PC (Recommended, via ADB Forwarding):${NC}"
    ["final_client_adb_cn"]="      1. 手机 USB 连接电脑，并在开发者选项中开启【USB 调试】。\n      2. 在 Windows 终端执行命令: ${YELLOW}adb forward tcp:5901 tcp:5901${NC}\n      3. 电脑端打开 TigerVNC 客户端，连接地址填写: ${YELLOW}127.0.0.1:5901${NC}"
    ["final_client_adb_en"]="      1. Connect phone via USB and enable [USB Debugging].\n      2. Run in Windows CMD: ${YELLOW}adb forward tcp:5901 tcp:5901${NC}\n      3. Open TigerVNC client on PC, connect to: ${YELLOW}127.0.0.1:5901${NC}"

    # 结束汇总 - 排障指南
    ["final_faq_title_cn"]="${RED}🛠️ 常见问题与解决方案：${NC}"
    ["final_faq_title_en"]="${RED}🛠️ Troubleshooting & FAQ:${NC}"
    ["final_faq_1_cn"]="  ${YELLOW}1. VNC 突然连不上、黑屏或一直超时？${NC}\n     -> 通常是 Android 强杀后台导致。请在多任务界面彻底划掉(关闭)终端 App，重新打开即可。建议在系统设置中将该 App 的【电池优化】改为【无限制】。"
    ["final_faq_1_en"]="  ${YELLOW}1. VNC connection refused, timeout, or black screen?${NC}\n     -> Usually caused by Android killing background processes. Swipe away/kill the terminal app, then reopen it. Set [Battery Optimization] to [Unrestricted] in Android settings."
    ["final_faq_2_cn"]="  ${YELLOW}2. 桌面无法输入中文 / Fcitx5 没出来？${NC}\n     -> 输入法框架需要重启桌面生效。请彻底重启终端 App，或者执行 'vncserver -kill :1 && vncserver :1' 重启 VNC。"
    ["final_faq_2_en"]="  ${YELLOW}2. Cannot type Chinese / Fcitx5 not showing?${NC}\n     -> Input framework needs a restart. Close and reopen the terminal app, or run 'vncserver -kill :1 && vncserver :1'."
    ["final_faq_3_cn"]="  ${YELLOW}3. 桌面的 'Android文件' 共享目录是空的？${NC}\n     -> 请前往 Android 系统设置 -> 应用权限，确保赋予了该虚拟机 App 【访问所有文件 / 存储】 权限。"
    ["final_faq_3_en"]="  ${YELLOW}3. The 'Android_Files' shared folder is empty?${NC}\n     -> Go to Android Settings -> App Permissions, and ensure the VM app has [All Files Access / Storage] permission."
)

function lang() { local key="${1}_${LANG_CHOICE}"; printf -- "${messages[$key]}"; }
function info() { echo -e "${GREEN}[INFO]${NC} $1"; }
function error() { echo -e "${RED}[ERROR]${NC} $1"; }
function banner() { echo -e "${BLUE}============================================================${NC}\n${BLUE}$1${NC}\n${BLUE}============================================================${NC}"; }
function run_cmd() { if ! "$@"; then error "$(printf "$(lang command_fail)" "$*")"; exit 1; fi; }
function install_package() { local pkg_name=$1; if ! sudo apt install -y "$pkg_name"; then error "$(printf "$(lang install_fail)" "$pkg_name")"; exit 1; fi; }

# --- 步骤 1: 用户交互 ---
function user_selections() {
    clear
    banner "$(lang welcome_banner)"
    
    echo -e "$(lang select_lang_prompt)"
    echo "$(lang lang_choice_cn)"
    echo "$(lang lang_choice_en)"
    read -p "$(lang enter_lang_num)" lang_choice_num
    case $lang_choice_num in 2) LANG_CHOICE="en" ;; *) LANG_CHOICE="cn" ;; esac
    
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

    clear; banner "$(lang confirm_banner)"
    echo "$(lang confirm_intro)"; printf "$(lang confirm_user)\n"; printf "$(lang confirm_desktop) '$DESKTOP_NAME'\n"
    read -p "$(lang confirm_proceed)" confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then exit 0; fi
}

# --- 步骤 2: 系统准备与语言锁定 ---
function prepare_system() {
    banner "$(lang update_pkg)"; run_cmd sudo apt-get update -y
    banner "$(lang upgrade_pkg)"; run_cmd sudo apt-get upgrade -y
    
    if ! grep -q "$(hostname)" /etc/hosts; then echo "127.0.0.1 $(hostname)" | sudo tee -a /etc/hosts > /dev/null; fi

    banner "$(lang locale_check)"
    install_package "locales"
    
    if [ "$LANG_CHOICE" == "cn" ]; then
        SYS_LOCALE="zh_CN.UTF-8"
        sudo sed -i 's/^# *\(zh_CN.UTF-8 UTF-8\)/\1/' /etc/locale.gen
        sudo sed -i 's/^# *\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen
    else
        SYS_LOCALE="en_US.UTF-8"
        sudo sed -i 's/^# *\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen
    fi
    
    run_cmd sudo locale-gen
    sudo update-locale LANG=$SYS_LOCALE
    
    if ! grep -q "export LANG=" ~/.bashrc; then
        echo "export LANG=$SYS_LOCALE" >> ~/.bashrc
        echo "export LC_ALL=$SYS_LOCALE" >> ~/.bashrc
    else
        sed -i "s/export LANG=.*/export LANG=$SYS_LOCALE/" ~/.bashrc
        sed -i "s/export LC_ALL=.*/export LC_ALL=$SYS_LOCALE/" ~/.bashrc
    fi
    
    install_package "fonts-noto-cjk"; install_package "fonts-wqy-zenhei"; install_package "fonts-wqy-microhei"
}

# --- 步骤 3: 注入 Android 网络桥接补丁 ---
function fix_android_network_bridge() {
    banner "$(lang network_fix)"
    sudo mkdir -p /etc/systemd/system/ssh.service.d
    cat << 'EOF' | sudo tee /etc/systemd/system/ssh.service.d/wait-network.conf > /dev/null
[Unit]
After=network-online.target
Wants=network-online.target
EOF

    sudo mkdir -p /etc/systemd/system/tigervncserver@.service.d
    cat << 'EOF' | sudo tee /etc/systemd/system/tigervncserver@.service.d/wait-network.conf > /dev/null
[Unit]
After=network-online.target
Wants=network-online.target
EOF
    sudo systemctl daemon-reload
}

# --- 步骤 4: SSH 配置 ---
function setup_ssh() {
    banner "$(lang ssh_modify)"; install_package "openssh-server"

    if sudo systemctl is-active --quiet ssh.socket 2>/dev/null || sudo systemctl is-enabled --quiet ssh.socket 2>/dev/null; then
        sudo systemctl disable --now ssh.socket 2>/dev/null || true
        sudo systemctl enable --now ssh.service 2>/dev/null || true
    fi

    sudo sed -i -E -e 's/^#?\s*Port\s+[0-9]+/Port 10022/' -e 's/^#?\s*PasswordAuthentication\s+no/PasswordAuthentication yes/' /etc/ssh/sshd_config
    if ! sudo grep -q "^Port 10022" /etc/ssh/sshd_config; then echo "Port 10022" | sudo tee -a /etc/ssh/sshd_config > /dev/null; fi
    if ! sudo grep -q "^PasswordAuthentication yes" /etc/ssh/sshd_config; then echo "PasswordAuthentication yes" | sudo tee -a /etc/ssh/sshd_config > /dev/null; fi
    if ! sudo grep -q "^ListenAddress 0.0.0.0" /etc/ssh/sshd_config; then echo "ListenAddress 0.0.0.0" | sudo tee -a /etc/ssh/sshd_config > /dev/null; fi
    
    if systemctl list-unit-files | grep -q "^ssh.service"; then
        run_cmd sudo systemctl restart ssh
    else
        run_cmd sudo systemctl restart sshd
    fi
}

# --- 步骤 5: 安装桌面环境 ---
function install_desktop() {
    banner "$(printf "$(lang desktop_install)" "$DESKTOP_NAME")"
    install_package "tasksel"; run_cmd sudo tasksel install $TASKSEL_TASK
}

# --- 步骤 6: VNC 配置 ---
function setup_vnc() {
    banner "$(lang vnc_config)"
    install_package "tigervnc-standalone-server"; install_package "tigervnc-common"; install_package "dbus-x11"
    
    sudo mkdir -p /tmp/.X11-unix; sudo chmod 1777 /tmp/.X11-unix
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
}

# --- 步骤 7: 挂载 Android 共享目录 ---
function setup_android_shared() {
    banner "$(lang android_share_banner)"
    install_package "xdg-user-dirs"; xdg-user-dirs-update
    sudo mkdir -p /mnt/shared
    
    DESKTOP_DIR=$(xdg-user-dir DESKTOP 2>/dev/null)
    if [ -z "$DESKTOP_DIR" ]; then DESKTOP_DIR="$HOME/Desktop"; fi
    mkdir -p "$DESKTOP_DIR"
    
    if [ "$LANG_CHOICE" == "cn" ]; then LINK_NAME="Android文件"; else LINK_NAME="Android_Files"; fi
    ln -sf /mnt/shared "$DESKTOP_DIR/$LINK_NAME"
    
    mkdir -p ~/.config/gtk-3.0
    touch ~/.config/gtk-3.0/bookmarks
    if ! grep -q "file:///mnt/shared" ~/.config/gtk-3.0/bookmarks; then
        if [ "$LANG_CHOICE" == "cn" ]; then
            echo "file:///mnt/shared 📱Android_共享磁盘" >> ~/.config/gtk-3.0/bookmarks
        else
            echo "file:///mnt/shared 📱Android_Shared_Disk" >> ~/.config/gtk-3.0/bookmarks
        fi
    fi
}

# --- 步骤 8: 可选组件 ---
function optional_components() {
    read -p "$(lang input_method_prompt)" install_ime
    if [[ "$install_ime" =~ ^[Yy]$ ]]; then
        banner "$(lang ime_install_banner)"
        install_package "fcitx5"; install_package "fcitx5-chinese-addons"
        install_package "fcitx5-frontend-gtk3"; install_package "fcitx5-frontend-qt5"
        install_package "im-config"; im-config -n fcitx5
    fi

    echo ""; echo -e "$(lang common_apps_desc)"
    read -p "$(lang common_apps_prompt)" install_apps
    if [[ "$install_apps" =~ ^[Yy]$ ]]; then
        banner "$(lang apps_install_banner)"
        install_package "curl"; install_package "wget"; install_package "git"; install_package "htop"
        install_package "unzip"; install_package "p7zip-full"; install_package "chromium"
        install_package "vlc"; install_package "gimp"; install_package "flameshot"
        install_package "remmina"; install_package "libreoffice"
        if [ "$LANG_CHOICE" == "cn" ]; then install_package "libreoffice-l10n-zh-cn"; fi
    fi
}

# --- 步骤 9: 总结与排障信息 ---
function final_summary() {
    clear; banner "$(lang final_summary)"
    
    echo -e "$(lang final_client_title)"
    echo -e "$(lang final_client_phone)"
    echo -e "$(lang final_client_pc)"
    echo -e "$(lang final_client_adb)\n"
    
    echo -e "$(lang final_faq_title)"
    echo -e "$(lang final_faq_1)\n"
    echo -e "$(lang final_faq_2)\n"
    echo -e "$(lang final_faq_3)\n"
}

# --- 主程序入口 ---
function main() {
    user_selections
    prepare_system
    fix_android_network_bridge
    setup_ssh
    install_desktop
    setup_vnc
    setup_android_shared
    optional_components
    final_summary
}

main
