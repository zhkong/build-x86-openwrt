#!/bin/bash
# ============================================================
# 中文语言环境配置功能
# ============================================================

# 加载通用配置
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# ==================== 中文语言环境配置 ====================
setup_chinese_locale() {
    local files_dir="${1:-$FILES_DIR}"
    
    echo ""
    echo "[2/4] 配置中文语言环境..."
    
    # 创建 locale 配置目录
    mkdir -p "$files_dir/etc/profile.d"
    
    # 终端 UTF-8 配置
    cat > "$files_dir/etc/profile.d/99-utf8-terminal.sh" << 'EOF'
#!/bin/sh
export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8
export LANGUAGE=zh_CN:zh:en_US:en
if [ "$TERM" = "xterm" ] || [ "$TERM" = "screen" ]; then
    export TERM="${TERM}-256color"
fi
EOF
    chmod +x "$files_dir/etc/profile.d/99-utf8-terminal.sh"
    
    # 创建 UCI defaults 脚本设置系统语言和主题
    mkdir -p "$files_dir/etc/uci-defaults"
    cat > "$files_dir/etc/uci-defaults/99-set-chinese-locale" << 'UCIEOF'
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
    chmod +x "$files_dir/etc/uci-defaults/99-set-chinese-locale"
    
    echo "  ✓ 中文语言环境配置完成"
    echo "  ✓ 已设置 Argon 为默认主题"
}
