#!/bin/bash
# ============================================================
# 终端工具配置功能
# ============================================================

# 加载通用配置
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# ==================== 终端工具配置 ====================
setup_terminal_tools() {
    local files_dir="${1:-$FILES_DIR}"
    
    echo ""
    echo "[1/4] 配置终端工具 (Zsh + Oh-My-Zsh)..."
    
    mkdir -p "$files_dir/root"
    mkdir -p "$files_dir/etc/profile.d"
    mkdir -p "$files_dir/usr/libexec/uci-defaults"
    
    # 安装 Oh-My-Zsh
    echo "  克隆 oh-my-zsh 仓库..."
    if [ ! -d "$files_dir/root/.oh-my-zsh" ]; then
        git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$files_dir/root/.oh-my-zsh"
    else
        echo "  oh-my-zsh 已存在，跳过"
    fi
    
    # 安装 Zsh 插件
    echo "  安装 zsh 插件..."
    local plugins_dir="$files_dir/root/.oh-my-zsh/custom/plugins"
    
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
        cp "$DATA_DIR/zsh/.zshrc" "$files_dir/root/.zshrc"
        echo "    ✓ 使用 data/zsh/.zshrc"
    else
        create_default_zshrc "$files_dir"
        echo "    ✓ 使用默认配置"
    fi
    
    # 设置 zsh 为默认 shell
    echo "  设置默认 shell 为 zsh..."
    
    # 创建首次启动脚本，在首次启动时设置默认 shell
    cat > "$files_dir/usr/libexec/uci-defaults/99-set-default-shell-zsh" << 'UCIEOF'
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
    chmod +x "$files_dir/usr/libexec/uci-defaults/99-set-default-shell-zsh"
    echo "    ✓ 已创建 uci-defaults 脚本，将在首次启动时设置 zsh 为默认 shell"
    
    # 创建 .profile
    cat > "$files_dir/root/.profile" << 'PROFILE'
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
    find "$files_dir/root/.oh-my-zsh" -name ".git" -type d -exec rm -rf {} + 2>/dev/null || true
    
    echo "  ✓ 终端工具配置完成"
}

# 创建默认 .zshrc
create_default_zshrc() {
    local files_dir="${1:-$FILES_DIR}"
    cat > "$files_dir/root/.zshrc" << 'ZSHRC'
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
