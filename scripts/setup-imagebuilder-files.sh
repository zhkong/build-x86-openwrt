#!/bin/bash
# ============================================================
# ImmortalWrt ImageBuilder 自定义文件创建脚本
# 创建所有需要嵌入固件的自定义文件
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DATA_DIR="$PROJECT_DIR/data"

# 自定义文件输出目录（可通过参数指定）
FILES_DIR="${1:-$PROJECT_DIR/imagebuilder/custom-files}"

echo "=========================================="
echo "创建 ImageBuilder 自定义文件"
echo "输出目录: $FILES_DIR"
echo "=========================================="

# 清理并创建目录
rm -rf "$FILES_DIR"
mkdir -p "$FILES_DIR"

# ==================== 终端工具配置 ====================
setup_terminal_tools() {
    echo ""
    echo "[1/2] 配置终端工具 (Zsh + Oh-My-Zsh)..."
    
    mkdir -p "$FILES_DIR/root"
    mkdir -p "$FILES_DIR/etc/profile.d"
    mkdir -p "$FILES_DIR/usr/libexec/uci-defaults"
    
    # 安装 Oh-My-Zsh
    echo "  克隆 oh-my-zsh 仓库..."
    if [ ! -d "$FILES_DIR/root/.oh-my-zsh" ]; then
        git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$FILES_DIR/root/.oh-my-zsh"
    else
        echo "  oh-my-zsh 已存在，跳过"
    fi
    
    # 安装 Zsh 插件
    echo "  安装 zsh 插件..."
    local plugins_dir="$FILES_DIR/root/.oh-my-zsh/custom/plugins"
    
    # zsh-autosuggestions
    if [ ! -d "$plugins_dir/zsh-autosuggestions" ]; then
        git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$plugins_dir/zsh-autosuggestions"
        echo "    ✓ zsh-autosuggestions"
    fi
    
    # zsh-syntax-highlighting
    if [ ! -d "$plugins_dir/zsh-syntax-highlighting" ]; then
        git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$plugins_dir/zsh-syntax-highlighting"
        echo "    ✓ zsh-syntax-highlighting"
    fi
    
    # zsh-completions
    if [ ! -d "$plugins_dir/zsh-completions" ]; then
        git clone --depth=1 https://github.com/zsh-users/zsh-completions "$plugins_dir/zsh-completions"
        echo "    ✓ zsh-completions"
    fi
    
    # 复制 .zshrc 配置文件
    echo "  配置 .zshrc..."
    if [ -f "$DATA_DIR/zsh/.zshrc" ]; then
        cp "$DATA_DIR/zsh/.zshrc" "$FILES_DIR/root/.zshrc"
        echo "    ✓ 使用 data/zsh/.zshrc"
    else
        create_default_zshrc
        echo "    ✓ 使用默认配置"
    fi
    
    # 设置 zsh 为默认 shell
    echo "  设置默认 shell 为 zsh..."
    
    # 创建首次启动脚本，在首次启动时设置默认 shell
    cat > "$FILES_DIR/usr/libexec/uci-defaults/99-set-default-shell-zsh" << 'UCIEOF'
#!/bin/sh
# 设置 root 用户默认 shell 为 zsh
if [ -x /usr/bin/zsh ]; then
    # 检查当前 shell 是否为 ash，如果是则改为 zsh
    if grep -q "root:.*:/bin/ash" /etc/passwd 2>/dev/null; then
        sed -i 's|root:\([^:]*\):\([^:]*\):\([^:]*\):\([^:]*\):\([^:]*\):/bin/ash|root:\1:\2:\3:\4:\5:/usr/bin/zsh|' /etc/passwd
        echo "Default shell changed to zsh"
    fi
fi
exit 0
UCIEOF
    chmod +x "$FILES_DIR/usr/libexec/uci-defaults/99-set-default-shell-zsh"
    echo "    ✓ 已创建 uci-defaults 脚本，将在首次启动时设置 zsh 为默认 shell"
    
    # 创建 .profile
    cat > "$FILES_DIR/root/.profile" << 'PROFILE'
# ~/.profile: executed by the command interpreter for login shells
export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8
export LANGUAGE=zh_CN:zh:en_US:en
export TERM=xterm-256color
if [ -z "$ZSH_VERSION" ]; then
    [ -f /etc/banner ] && cat /etc/banner
fi
PROFILE

    # 清理 Git 目录
    echo "  清理 Git 目录以减小体积..."
    find "$FILES_DIR/root/.oh-my-zsh" -name ".git" -type d -exec rm -rf {} + 2>/dev/null || true
    
    echo "  ✓ 终端工具配置完成"
}

# ==================== 中文语言环境配置 ====================
setup_chinese_locale() {
    echo ""
    echo "[2/2] 配置中文语言环境..."
    
    # 创建 locale 配置目录
    mkdir -p "$FILES_DIR/etc/profile.d"
    
    # 终端 UTF-8 配置
    cat > "$FILES_DIR/etc/profile.d/99-utf8-terminal.sh" << 'EOF'
#!/bin/sh
export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8
export LANGUAGE=zh_CN:zh:en_US:en
if [ "$TERM" = "xterm" ] || [ "$TERM" = "screen" ]; then
    export TERM="${TERM}-256color"
fi
EOF
    chmod +x "$FILES_DIR/etc/profile.d/99-utf8-terminal.sh"
    
    # 创建 UCI defaults 脚本设置系统语言
    mkdir -p "$FILES_DIR/etc/uci-defaults"
    cat > "$FILES_DIR/etc/uci-defaults/99-set-chinese-locale" << 'UCIEOF'
#!/bin/sh
# 设置系统语言为中文
export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8
export LANGUAGE=zh_CN:zh:en_US:en

# 如果 /etc/config/luci 存在，设置语言
if [ -f /etc/config/luci ]; then
    uci set luci.main.lang=zh_cn 2>/dev/null || true
    uci commit luci 2>/dev/null || true
fi

exit 0
UCIEOF
    chmod +x "$FILES_DIR/etc/uci-defaults/99-set-chinese-locale"
    
    echo "  ✓ 中文语言环境配置完成"
}

# 创建默认 .zshrc
create_default_zshrc() {
    cat > "$FILES_DIR/root/.zshrc" << 'ZSHRC'
# ImmortalWrt Zsh 配置
export ZSH="$HOME/.oh-my-zsh"
export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8
export TERM=xterm-256color

ZSH_THEME="agnoster"
DEFAULT_USER="root"
DISABLE_AUTO_UPDATE="true"

plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions)

source $ZSH/oh-my-zsh.sh

# 显示 ImmortalWrt Banner
if [[ -o login ]] && [[ -o interactive ]]; then
    [[ -f /etc/banner ]] && cat /etc/banner
fi

# 别名
alias ll='ls -alFh --color=auto'
alias la='ls -A --color=auto'
alias logs='logread -f'
alias syslog='logread'
ZSHRC
}

# ==================== 显示摘要 ====================
show_summary() {
    echo ""
    echo "[完成] 清理和统计..."
    
    local total_size=$(du -sh "$FILES_DIR" 2>/dev/null | cut -f1)
    local file_count=$(find "$FILES_DIR" -type f | wc -l)
    
    echo ""
    echo "=========================================="
    echo "自定义文件创建完成！"
    echo "=========================================="
    echo "输出目录: $FILES_DIR"
    echo "文件数量: $file_count"
    echo "总大小:   $total_size"
    echo ""
    echo "包含功能:"
    echo "  ✓ Zsh 默认 Shell"
    echo "  ✓ Oh-My-Zsh + Agnoster 主题"
    echo "  ✓ Zsh 插件 (autosuggestions, syntax-highlighting, completions)"
    echo "  ✓ UTF-8 终端支持"
    echo "  ✓ 中文语言环境"
    echo "=========================================="
}

# ==================== 主程序 ====================
main() {
    setup_terminal_tools
    setup_chinese_locale
    show_summary
}

main "$@"
