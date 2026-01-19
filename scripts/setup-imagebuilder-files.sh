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

# 复制项目根目录下的 files 目录内容（如果存在）
PROJECT_FILES_DIR="$PROJECT_DIR/files"
if [ -d "$PROJECT_FILES_DIR" ]; then
    echo ""
    echo "[0/4] 复制项目自定义文件..."
    echo "  源目录: $PROJECT_FILES_DIR"
    echo "  目标目录: $FILES_DIR"
    cp -r "$PROJECT_FILES_DIR"/* "$FILES_DIR/" 2>/dev/null || {
        # 如果 cp -r 失败，尝试使用 rsync 或逐个文件复制
        if command -v rsync &> /dev/null; then
            rsync -av "$PROJECT_FILES_DIR/" "$FILES_DIR/"
        else
            find "$PROJECT_FILES_DIR" -type f -exec sh -c 'mkdir -p "$(dirname "$2")" && cp "$1" "$2"' _ {} "$FILES_DIR/{}" \;
        fi
    }
    echo "  ✓ 项目自定义文件复制完成"
else
    echo ""
    echo "[0/4] 跳过项目自定义文件复制（目录不存在: $PROJECT_FILES_DIR）"
fi

# ==================== 终端工具配置 ====================
setup_terminal_tools() {
    echo ""
    echo "[1/4] 配置终端工具 (Zsh + Oh-My-Zsh)..."
    
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
    echo "[2/4] 配置中文语言环境..."
    
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
    
    # 创建 UCI defaults 脚本设置系统语言和主题
    mkdir -p "$FILES_DIR/etc/uci-defaults"
    cat > "$FILES_DIR/etc/uci-defaults/99-set-chinese-locale" << 'UCIEOF'
#!/bin/sh
# 设置系统语言为中文
export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8
export LANGUAGE=zh_CN:zh:en_US:en

# 如果 /etc/config/luci 存在，设置语言和主题
if [ -f /etc/config/luci ]; then
    uci set luci.main.lang=zh_cn 2>/dev/null || true
    # 设置默认主题为 argon
    if uci get luci.main.mediaurlbase >/dev/null 2>&1; then
        uci set luci.main.mediaurlbase='/luci-static/argon' 2>/dev/null || true
    fi
    uci commit luci 2>/dev/null || true
fi

exit 0
UCIEOF
    chmod +x "$FILES_DIR/etc/uci-defaults/99-set-chinese-locale"
    
    echo "  ✓ 中文语言环境配置完成"
    echo "  ✓ 已设置 Argon 为默认主题"
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
    echo "  ✓ Nikki 透明代理 (Mihomo)"
    echo "  ✓ Metacubexd 控制面板"
    echo "=========================================="
}

# ==================== Nikki Dashboard 下载 ====================
setup_nikki_dashboard() {
    echo ""
    echo "[3/4] 下载 Nikki 控制面板 (Metacubexd)..."
    
    local ui_dir="$FILES_DIR/etc/nikki/run/ui"
    mkdir -p "$ui_dir"
    
    # 获取最新版本信息
    echo "  获取最新版本信息..."
    local release_info=$(curl -fsSL "https://api.github.com/repos/MetaCubeX/metacubexd/releases/latest" 2>/dev/null)
    
    if [ -z "$release_info" ]; then
        echo "  警告: 无法获取版本信息，使用备用下载链接"
        local download_url="https://github.com/MetaCubeX/metacubexd/releases/latest/download/compressed-dist.tgz"
        local version="latest"
    else
        local version=$(echo "$release_info" | grep -oP '"tag_name":\s*"\K[^"]+' | head -1)
        local download_url=$(echo "$release_info" | grep -oP '"browser_download_url":\s*"\K[^"]+compressed-dist\.tgz' | head -1)
        
        if [ -z "$download_url" ]; then
            download_url="https://github.com/MetaCubeX/metacubexd/releases/latest/download/compressed-dist.tgz"
        fi
    fi
    
    echo "  版本: ${version:-latest}"
    echo "  下载: $download_url"
    
    # 下载并解压
    local tmp_file="/tmp/metacubexd.tgz"
    if curl -fsSL -o "$tmp_file" "$download_url" 2>/dev/null; then
        echo "  解压控制面板..."
        tar -xzf "$tmp_file" -C "$ui_dir" 2>/dev/null
        rm -f "$tmp_file"
        
        # 统计文件数量
        local file_count=$(find "$ui_dir" -type f | wc -l)
        echo "  ✓ Metacubexd 控制面板下载完成 ($file_count 个文件)"
    else
        echo "  警告: 下载失败，控制面板将需要手动安装"
        echo "  可在路由器启动后访问 LuCI → 服务 → Nikki 下载"
    fi
}

# ==================== Nikki Feed 配置 ====================
setup_nikki_feed() {
    echo ""
    echo "[4/4] 配置 Nikki 软件源..."
    
    # 获取 ImageBuilder 目录
    local imagebuilder_dir="$PROJECT_DIR/imagebuilder"
    local ib_dir=$(find "$imagebuilder_dir" -maxdepth 1 -type d -name "immortalwrt-imagebuilder-*" 2>/dev/null | head -1)
    
    if [ -z "$ib_dir" ] || [ ! -d "$ib_dir" ]; then
        echo "  警告: 未找到 ImageBuilder 目录，跳过 Nikki feed 配置"
        echo "  将在构建时自动配置"
        return 0
    fi
    
    local repos_conf="$ib_dir/repositories.conf"
    local keys_dir="$ib_dir/keys"
    
    if [ ! -f "$repos_conf" ]; then
        echo "  警告: 未找到 repositories.conf，跳过 Nikki feed 配置"
        return 0
    fi
    
    # 从 repositories.conf 获取版本信息
    local version=$(grep -oP 'releases/\K[0-9]+\.[0-9]+\.[0-9]+' "$repos_conf" | head -1)
    local arch=$(grep -oP 'packages/\K[^/]+(?=/base)' "$repos_conf" | head -1)
    
    if [ -z "$version" ] || [ -z "$arch" ]; then
        echo "  警告: 无法从 repositories.conf 获取版本/架构信息"
        echo "  使用默认值: version=24.10, arch=x86_64"
        version="24.10"
        arch="x86_64"
    fi
    
    # 构建 nikki feed URL
    local nikki_feed_url="https://nikkinikki.pages.dev/openwrt-${version%.*}/${arch}/nikki"
    echo "  Nikki Feed URL: $nikki_feed_url"
    
    # 检查是否已添加 nikki feed
    if grep -q "nikki" "$repos_conf"; then
        echo "  Nikki feed 已存在，跳过"
    else
        # 在 imagebuilder 本地源之前添加 nikki feed
        sed -i "/^src imagebuilder/i src/gz nikki ${nikki_feed_url}" "$repos_conf"
        echo "  ✓ 已添加 Nikki feed 到 repositories.conf"
    fi
    
    # 由于添加了第三方软件源（nikki），需要禁用签名检查
    # ImageBuilder 的 usign 工具不支持运行时添加新公钥
    echo "  配置软件包签名..."
    if grep -q "^option check_signature" "$repos_conf"; then
        sed -i 's/^option check_signature/# option check_signature/' "$repos_conf"
        echo "  ✓ 已禁用软件包签名检查（第三方源需要）"
    else
        echo "  签名检查已禁用，跳过"
    fi
    
    echo "  ✓ Nikki 软件源配置完成"
}

# ==================== 主程序 ====================
main() {
    setup_terminal_tools
    setup_chinese_locale
    setup_nikki_dashboard
    setup_nikki_feed
    show_summary
}

main "$@"
