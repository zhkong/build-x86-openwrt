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
    echo "  ✓ YACD 控制面板"
    echo "  ✓ Nikki 地理位置数据 (Country.mmdb, GeoSite.dat)"
    echo "=========================================="
}

# ==================== Nikki Dashboard 下载 ====================
setup_nikki_dashboard() {
    echo ""
    echo "[3/4] 下载 Nikki 控制面板 (YACD)..."
    
    local ui_dir="$FILES_DIR/etc/nikki/run/ui"
    mkdir -p "$ui_dir"
    
    # 从 gh-pages 分支下载 YACD
    local download_url="https://github.com/haishanh/yacd/archive/gh-pages.zip"
    echo "  下载: $download_url"
    
    # 下载并解压
    local tmp_file="/tmp/yacd.zip"
    local tmp_dir="/tmp/yacd_extract"
    
    # 清理可能存在的旧文件
    rm -f "$tmp_file"
    rm -rf "$tmp_dir"
    
    if curl -fsSL --connect-timeout 30 --max-time 300 -o "$tmp_file" "$download_url" 2>/dev/null; then
        # 检查下载的文件大小
        local file_size=$(stat -f%z "$tmp_file" 2>/dev/null || stat -c%s "$tmp_file" 2>/dev/null || echo "0")
        if [ "$file_size" -lt 1000 ]; then
            echo "  ✗ 警告: 下载的文件过小 ($file_size 字节)，可能下载失败"
            rm -f "$tmp_file"
        else
            echo "  下载文件大小: ${file_size} 字节"
            echo "  解压控制面板..."
            mkdir -p "$tmp_dir"
        
            # 解压到临时目录
            if unzip -q -o "$tmp_file" -d "$tmp_dir" 2>/dev/null; then
                # 查找解压后的目录（通常是 yacd-gh-pages）
                local extracted_dir=$(find "$tmp_dir" -maxdepth 1 -type d -name "yacd-gh-pages" 2>/dev/null | head -1)
                
                if [ -n "$extracted_dir" ] && [ -d "$extracted_dir" ]; then
                    # 移动解压后的所有文件到 UI 目录（包括隐藏文件）
                    # 使用 find 确保包括隐藏文件
                    find "$extracted_dir" -mindepth 1 -maxdepth 1 -exec mv {} "$ui_dir/" \; 2>/dev/null || true
                    echo "  ✓ 文件已移动到目标目录"
                else
                    echo "  警告: 未找到预期的解压目录"
                    # 列出临时目录内容以便调试
                    echo "  临时目录内容:"
                    ls -la "$tmp_dir" 2>/dev/null || true
                    echo "  尝试直接解压到目标目录"
                    unzip -q -o "$tmp_file" -d "$ui_dir" 2>/dev/null || true
                fi
                
                # 清理临时文件
                rm -rf "$tmp_dir"
                rm -f "$tmp_file"
                
                # 统计文件数量
                local file_count=$(find "$ui_dir" -type f 2>/dev/null | wc -l)
                if [ "$file_count" -gt 0 ]; then
                    echo "  ✓ YACD 控制面板下载完成 ($file_count 个文件)"
                    
                    # 配置 Nikki 默认 UI 为 YACD
                    setup_nikki_default_ui
                else
                    echo "  ✗ 警告: 解压后未找到文件"
                    echo "  目标目录内容:"
                    ls -la "$ui_dir" 2>/dev/null || true
                fi
            else
                echo "  ✗ 警告: 解压失败，可能需要安装 unzip"
                rm -f "$tmp_file"
                rm -rf "$tmp_dir"
            fi
        fi
    else
        echo "  ✗ 警告: 下载失败，控制面板将需要手动安装"
        echo "  可在路由器启动后访问 LuCI → 服务 → Nikki 下载"
        rm -f "$tmp_file"
    fi
}

# 配置 Nikki 默认 UI 为 YACD
setup_nikki_default_ui() {
    echo "  配置 Nikki 默认 UI 为 YACD..."
    
    # 创建 mixin 配置文件设置 external-ui
    local mixin_dir="$FILES_DIR/etc/nikki"
    mkdir -p "$mixin_dir"
    
    # 创建 mixin 配置文件，设置 external-ui 为 YACD
    cat > "$mixin_dir/mixin.yaml" << 'MIXINEOF'
# Nikki Mixin 配置
# 设置默认 UI 为 YACD
external-ui: /etc/nikki/run/ui
MIXINEOF
    
    # 创建 UCI defaults 脚本，确保 UI 配置生效
    mkdir -p "$FILES_DIR/usr/libexec/uci-defaults"
    cat > "$FILES_DIR/usr/libexec/uci-defaults/99-set-nikki-ui-yacd" << 'UCIEOF'
#!/bin/sh
# 设置 Nikki 默认 UI 为 YACD
# 检查 UI 目录是否存在
if [ -d /etc/nikki/run/ui ] && [ "$(ls -A /etc/nikki/run/ui 2>/dev/null)" ]; then
    # 确保 mixin 配置文件存在且设置正确
    if [ ! -f /etc/nikki/mixin.yaml ] || ! grep -q "external-ui.*yacd\|external-ui.*/etc/nikki/run/ui" /etc/nikki/mixin.yaml 2>/dev/null; then
        mkdir -p /etc/nikki
        echo "external-ui: /etc/nikki/run/ui" >> /etc/nikki/mixin.yaml
    fi
    
    # 如果 UCI 配置支持 external-ui，也尝试设置
    if [ -f /etc/config/nikki ]; then
        uci set nikki.config.external_ui='/etc/nikki/run/ui' 2>/dev/null && uci commit nikki 2>/dev/null || true
    fi
    
    echo "Nikki default UI set to YACD"
fi
exit 0
UCIEOF
    chmod +x "$FILES_DIR/usr/libexec/uci-defaults/99-set-nikki-ui-yacd"
    echo "  ✓ 已创建 mixin 配置和 UCI defaults 脚本，将在首次启动时设置 YACD 为默认 UI"
}

# ==================== Nikki 数据文件下载 ====================
setup_nikki_geodata() {
    echo ""
    echo "[4/5] 下载 Nikki 地理位置数据文件..."
    
    local geodata_dir="$FILES_DIR/etc/nikki/run"
    mkdir -p "$geodata_dir"
    
    # 下载 Country.mmdb (GeoIP 数据库)
    echo "  下载 Country.mmdb..."
    local mmdb_url="https://github.com/MetaCubeX/meta-rules-dat/releases/latest/download/country.mmdb"
    local mmdb_file="$geodata_dir/Country.mmdb"
    
    if curl -fsSL --connect-timeout 30 --max-time 300 -o "$mmdb_file" "$mmdb_url" 2>/dev/null; then
        local mmdb_size=$(stat -f%z "$mmdb_file" 2>/dev/null || stat -c%s "$mmdb_file" 2>/dev/null || echo "0")
        if [ "$mmdb_size" -gt 100000 ]; then
            echo "  ✓ Country.mmdb 下载完成 (${mmdb_size} 字节)"
        else
            echo "  ✗ 警告: Country.mmdb 文件过小，可能下载失败"
            rm -f "$mmdb_file"
        fi
    else
        echo "  ✗ 警告: Country.mmdb 下载失败，Nikki 将在启动时自动下载"
    fi
    
    # 下载 GeoSite.dat
    echo "  下载 GeoSite.dat..."
    local geosite_url="https://github.com/MetaCubeX/meta-rules-dat/releases/latest/download/geosite.dat"
    local geosite_file="$geodata_dir/GeoSite.dat"
    
    if curl -fsSL --connect-timeout 30 --max-time 300 -o "$geosite_file" "$geosite_url" 2>/dev/null; then
        local geosite_size=$(stat -f%z "$geosite_file" 2>/dev/null || stat -c%s "$geosite_file" 2>/dev/null || echo "0")
        if [ "$geosite_size" -gt 1000000 ]; then
            echo "  ✓ GeoSite.dat 下载完成 (${geosite_size} 字节)"
        else
            echo "  ✗ 警告: GeoSite.dat 文件过小，可能下载失败"
            rm -f "$geosite_file"
        fi
    else
        echo "  ✗ 警告: GeoSite.dat 下载失败，Nikki 将在启动时自动下载"
    fi
    
    # 检查是否至少有一个文件下载成功
    if [ -f "$mmdb_file" ] || [ -f "$geosite_file" ]; then
        echo "  ✓ 地理位置数据文件下载完成"
    else
        echo "  ✗ 警告: 地理位置数据文件下载失败，Nikki 将在启动时自动下载"
    fi
}

# ==================== Nikki Feed 配置 ====================
setup_nikki_feed() {
    echo ""
    echo "[5/5] 配置 Nikki 软件源..."
    
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
    setup_nikki_geodata
    setup_nikki_feed
    show_summary
}

main "$@"
