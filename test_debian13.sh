#!/bin/bash

# ==============================================================================
# 脚本名称: Debian 桌面环境与远程访问一键安装脚本 (Debian 12/13 兼容版)
# 脚本功能: 自动化安装选择的桌面环境并配置好 SSH 和 TigerVNC 远程访问。
# 适用系统: Debian 12 (Bookworm) / Debian 13 (Trixie)
# 特点:
#   - 修复了 Debian 13 中 SSH Socket 激活导致端口修改失效的问题。
#   - 适配了 Debian 13 默认 Wayland 导致 VNC 黑屏的问题 (强制 X11 会话)。
#   - 输入法框架升级为适配 Debian 13 更佳的 fcitx5。
#   - 丰富了常用桌面与系统软件套件 (办公、多媒体、解压、开发工具等)。
#   - 全面支持中英文双语界面切换。
# ==============================================================================

# --- 全局变量和初始化 ---
LANG_CHOICE="cn"
TARGET_USER=$(whoami)

# 检查是否以 root 运行
if [ "$(id -u)" -eq 0 ]; then
  echo -e "\033[0;31m[ERROR]\033[0m 请不要以 root 用户身份运行此脚本。请使用一个普通用户账户运行，脚本会在需要时请求 sudo 权限。"
  echo -e "\033[0;31m[ERROR]\033[0m Please do not run this script as root. Run it as a regular user, and it will ask for sudo password when needed."
  exit 1
fi

# 检查 sudo 是否安装
if ! command -v sudo &> /dev/null; then
  echo -e "\033[0;31m[ERROR]\033[0m 未找到 'sudo' 命令。请先以 root 身份执行 'apt install sudo'，并将当前用户加入 sudo 组。"
  echo -e "\033[0;31m[ERROR]\033[0m 'sudo' command not found. Please install it as root ('apt install sudo') and add your user to the sudo group."
  exit 1
fi

# --- 颜色定义 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- 多语言消息定义 ---
declare -A messages
messages=(
    # --- 通用 ---
    ["press_enter_cn"]="按回车键继续..."
    ["press_enter_en"]="Press Enter to continue..."
    ["invalid_option_cn"]="无效的选项，请重试。"
    ["invalid_option_en"]="Invalid option, please try again."
    ["operation_cancelled_cn"]="操作已取消。"
    ["operation_cancelled_en"]="Operation cancelled."

    # --- 信息 ---
    ["install_success_cn"]="成功安装 %s"
    ["install_success_en"]="Successfully installed %s"
    ["config_success_cn"]="成功配置 %s"
    ["config_success_en"]="Successfully configured %s"

    # --- 错误 ---
    ["install_fail_cn"]="安装 %s 失败"
    ["install_fail_en"]="Failed to install %s"
    ["config_fail_cn"]="配置 %s 失败"
    ["config_fail_en"]="Failed to configure %s"
    ["command_fail_cn"]="命令执行失败: %s"
    ["command_fail_en"]="Command failed: %s"
    
    # --- 流程 ---
    ["welcome_banner_cn"]="欢迎使用 Debian 桌面环境一键安装脚本"
    ["welcome_banner_en"]="Welcome to the Debian Desktop Environment One-Click Installer"
    ["select_lang_prompt_cn"]="请选择脚本界面语言 / Please select script UI language:"
    ["select_lang_prompt_en"]="Please select script UI language / 请选择脚本界面语言:"
    ["lang_choice_cn_cn"]="1. 中文 (默认)"
    ["lang_choice_cn_en"]="1. Chinese (Default)"
    ["lang_choice_en_cn"]="2. English"
    ["lang_choice_en_en"]="2. English"
    ["enter_lang_num_cn"]="输入数字 / Enter number (1/2): "
    ["enter_lang_num_en"]="Enter number / 输入数字 (1/2): "
    ["set_password_prompt_cn"]="是否为用户 '$TARGET_USER' 设置或更改登录密码？(y/n): "
    ["set_password_prompt_en"]="Set or change the login password for user '$TARGET_USER'? (y/n): "
    ["desktop_select_cn"]="选择您想安装的桌面环境"
    ["desktop_select_en"]="Select the desktop environment you want to install"
    ["enter_desktop_num_cn"]="请输入您想安装的桌面环境编号: "
    ["enter_desktop_num_en"]="Please enter the number for the desktop environment: "
    ["confirm_banner_cn"]="安装确认"
    ["confirm_banner_en"]="Installation Confirmation"
    ["confirm_intro_cn"]="将在系统上执行以下操作:"
    ["confirm_intro_en"]="The following actions will be performed on your system:"
    ["confirm_user_cn"]="  - 用户: '$TARGET_USER'"
    ["confirm_user_en"]="  - User: '$TARGET_USER'"
    ["confirm_desktop_cn"]="  - 安装桌面: "
    ["confirm_desktop_en"]="  - Install Desktop: "
    ["confirm_ssh_cn"]="  - 配置 SSH 服务 (端口 10022)"
    ["confirm_ssh_en"]="  - Configure SSH Service (Port 10022)"
    ["confirm_vnc_cn"]="  - 配置 VNC 服务 (端口 5901)"
    ["confirm_vnc_en"]="  - Configure VNC Service (Port 5901)"
    ["confirm_proceed_cn"]="是否继续? (y/n): "
    ["confirm_proceed_en"]="Do you want to continue? (y/n): "

    ["update_pkg_cn"]="正在更新软件包列表..."
    ["update_pkg_en"]="Updating package list..."
    ["upgrade_pkg_cn"]="正在升级已安装的软件包..."
    ["upgrade_pkg_en"]="Upgrading installed packages..."
    ["ssh_modify_cn"]="正在配置 SSH 服务器..."
    ["ssh_modify_en"]="Configuring SSH server..."
    ["ssh_port_prompt_cn"]="SSH 端口已配置为 10022。如果需要，请在防火墙或云服务商安全组中放行此端口。"
    ["ssh_port_prompt_en"]="SSH port is configured to 10022. Please allow it in your firewall or cloud provider's security group if needed."
    ["vnc_port_prompt_cn"]="VNC 服务已配置在 5901 端口。如果需要，请在防火墙或云服务商安全组中放行此端口。"
    ["vnc_port_prompt_en"]="VNC service is configured on port 5901. Please allow it in your firewall or cloud provider's security group if needed."
    ["locale_check_cn"]="正在检查系统语言环境 (Locale)..."
    ["locale_check_en"]="Checking system locale..."
    ["locale_utf8_ok_cn"]="检测到有效的 UTF-8 语言环境，跳过设置。"
    ["locale_utf8_ok_en"]="Valid UTF-8 locale detected, skipping setup."
    ["locale_utf8_fail_cn"]="未检测到 UTF-8 语言环境。即将进入交互式配置界面。"
    ["locale_utf8_fail_en"]="No UTF-8 locale detected. Entering interactive setup."
    ["locale_prompt_cn"]="请在接下来的界面中选择并生成您需要的语言环境 (推荐选择一个 UTF-8 选项, 例如 en_US.UTF-8 或 zh_CN.UTF-8)。"
    ["locale_prompt_en"]="In the following screens, please select and generate the locale you need (a UTF-8 option like en_US.UTF-8 or zh_CN.UTF-8 is recommended)."
    ["desktop_install_cn"]="正在安装 %s 桌面环境，这可能需要一些时间..."
    ["desktop_install_en"]="Installing %s desktop environment, this may take a while..."
    ["vnc_passwd_prompt_cn"]="接下来，请为您 VNC 会话设置一个密码 (至少6位)。"
    ["vnc_passwd_prompt_en"]="Next, please set a password for your VNC session (at least 6 characters)."
    ["vnc_config_cn"]="正在配置 TigerVNC..."
    ["vnc_config_en"]="Configuring TigerVNC..."
    
    # 软件安装新增部分
    ["input_method_prompt_cn"]="是否安装中文拼音输入法 (推荐新一代的 Fcitx5)? (y/n): "
    ["input_method_prompt_en"]="Install Chinese Pinyin input method (Fcitx5 recommended)? (y/n): "
    ["ime_install_banner_cn"]="正在安装中文输入法 (Fcitx5)..."
    ["ime_install_banner_en"]="Installing Chinese Input Method (Fcitx5)..."
    ["ime_config_done_cn"]="输入法配置完成，重启桌面或 VNC 服务后即可生效。"
    ["ime_config_done_en"]="Input method configured. It will take effect after restarting desktop or VNC service."
    
    ["common_apps_desc_cn"]="可选软件套件包含：\n  - 网页浏览器: Chromium\n  - 办公套件: LibreOffice (含中文语言包)\n  - 多媒体与图像: VLC 播放器, GIMP 图像编辑器\n  - 实用工具: Flameshot (截图), p7zip/unzip (解压缩), Remmina (远程桌面客户端)\n  - 系统与网络: htop, curl, wget, git"
    ["common_apps_desc_en"]="Optional software suite includes:\n  - Web Browser: Chromium\n  - Office Suite: LibreOffice\n  - Media & Graphics: VLC Player, GIMP Image Editor\n  - Utilities: Flameshot (Screenshot), p7zip/unzip (Archives), Remmina (Remote Desktop)\n  - System & Network: htop, curl, wget, git"
    ["common_apps_prompt_cn"]="是否安装上述常用桌面及系统软件套件? (y/n): "
    ["common_apps_prompt_en"]="Install the above common desktop & system software suite? (y/n): "
    ["apps_install_banner_cn"]="正在安装常用软件套件..."
    ["apps_install_banner_en"]="Installing common software suite..."

    ["final_summary_cn"]="🎉 所有配置已完成！"
    ["final_summary_en"]="🎉 All configurations completed!"
    ["final_info_cn"]="您现在可以使用以下信息进行远程连接："
    ["final_info_en"]="You can now connect using the following information:"
    ["final_ssh_header_cn"]="  ${YELLOW}SSH (命令行):${NC}"
    ["final_ssh_header_en"]="  ${YELLOW}SSH (Command Line):${NC}"
    ["final_vnc_header_cn"]="  ${YELLOW}VNC (图形桌面):${NC}"
    ["final_vnc_header_en"]="  ${YELLOW}VNC (Graphical Desktop):${NC}"
    ["final_vnc_addr_cn"]="    VNC 服务器地址: %s:1"
    ["final_vnc_addr_en"]="    VNC Server Address: %s:1"
    ["final_vnc_alt_cn"]="    (或者在客户端中输入 %s 和端口 5901)"
    ["final_vnc_alt_en"]="    (Or enter %s and port 5901 in your client)"
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

# 步骤1: 用户交互和选择
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
    echo "1. KDE Plasma"; echo "2. GNOME"; echo "3. XFCE"; echo "4. MATE"; echo "5. Cinnamon"; echo "6. LXQt"; echo "7. LXDE"; echo "8. GNOME Flashback (经典模式)"

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

# 步骤2: 系统准备
function prepare_system() {
    banner "$(lang update_pkg)"; run_cmd sudo apt-get update -y
    banner "$(lang upgrade_pkg)"; run_cmd sudo apt-get upgrade -y

    info "$(lang locale_check)"
    if ! locale | grep -q "UTF-8"; then
        warn "$(lang locale_utf8_fail)"
        info "$(lang locale_prompt)"
        prompt_continue
        install_package "locales"
        run_cmd sudo dpkg-reconfigure locales
    else
        info "$(lang locale_utf8_ok)"
    fi
}

# 步骤3: 安装和配置 SSH
function setup_ssh() {
    banner "$(lang ssh_modify)"; install_package "openssh-server"

    if sudo systemctl is-active --quiet ssh.socket 2>/dev/null || sudo systemctl is-enabled --quiet ssh.socket 2>/dev/null; then
        info "Detecting ssh.socket. Reverting to ssh.service for custom port support..."
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

# 步骤4: 安装桌面环境
function install_desktop() {
    banner "$(printf "$(lang desktop_install)" "$DESKTOP_NAME")"
    install_package "tasksel"
    run_cmd sudo tasksel install $TASKSEL_TASK
}

# 步骤5: 安装和配置 VNC
function setup_vnc() {
    banner "$(lang vnc_config)"; install_package "tigervnc-standalone-server"; install_package "tigervnc-common"
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
    info "$(printf "$(lang config_success)" "~/.vnc/config")"
    
    sudo mkdir -p /etc/tigervnc
    echo ":1=$TARGET_USER" | sudo tee /etc/tigervnc/vncserver.users >/dev/null
    info "$(printf "$(lang config_success)" "/etc/tigervnc/vncserver.users")"
    
    run_cmd sudo systemctl daemon-reload
    sudo systemctl enable tigervncserver@:1.service 2>/dev/null || true
    run_cmd sudo systemctl restart tigervncserver@:1.service
    info "$(lang vnc_port_prompt)"
}

# 步骤6: 可选组件 (输入法与常用软件)
function optional_components() {
    # 6.1 安装中文输入法
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

    # 6.2 安装丰富的常用软件套件
    echo ""
    echo -e "$(lang common_apps_desc)"
    read -p "$(lang common_apps_prompt)" install_apps
    if [[ "$install_apps" =~ ^[Yy]$ ]]; then
        banner "$(lang apps_install_banner)"
        
        # 基础系统工具
        install_package "curl"
        install_package "wget"
        install_package "git"
        install_package "htop"
        install_package "unzip"
        install_package "p7zip-full"
        
        # 桌面应用程序
        install_package "chromium"
        install_package "vlc"
        install_package "gimp"
        install_package "flameshot"
        install_package "remmina"
        install_package "libreoffice"
        
        # 如果选择了中文界面，自动给 LibreOffice 安装中文包
        if [ "$LANG_CHOICE" == "cn" ]; then
            install_package "libreoffice-l10n-zh-cn"
        fi
    fi
}

# 步骤7: 显示最终信息
function final_summary() {
    IP_ADDR=$(hostname -I | awk '{print $1}')
    clear; banner "$(lang final_summary)"; echo "$(lang final_info)"
    echo ""; echo -e "$(lang final_ssh_header)"
    echo -e "    ssh $TARGET_USER@$IP_ADDR -p 10022"
    echo ""; echo -e "$(lang final_vnc_header)"
    printf "    $(lang final_vnc_addr)\n" "$IP_ADDR"
    printf "    $(lang final_vnc_alt)\n" "$IP_ADDR"
    echo ""
}

# --- 主程序入口 ---
function main() {
    user_selections; prepare_system; setup_ssh; install_desktop; setup_vnc; optional_components; final_summary
}

# 执行主函数
main
