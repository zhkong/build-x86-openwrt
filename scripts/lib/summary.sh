#!/bin/bash
# ============================================================
# 摘要显示功能
# ============================================================

# 加载通用配置
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# ==================== 显示摘要 ====================
show_summary() {
    local files_dir="${1:-$FILES_DIR}"
    
    echo ""
    echo "[完成] 清理和统计..."
    
    local total_size=$(du -sh "$files_dir" 2>/dev/null | cut -f1)
    local file_count=$(find "$files_dir" -type f | wc -l)
    
    echo ""
    echo "=========================================="
    echo "自定义文件创建完成！"
    echo "=========================================="
    echo "输出目录: $files_dir"
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
