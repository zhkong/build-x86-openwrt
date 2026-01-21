#!/bin/bash
# ============================================================
# ImmortalWrt ImageBuilder 自定义文件创建脚本
# 创建所有需要嵌入固件的自定义文件
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

# 加载功能模块
source "$LIB_DIR/common.sh"
source "$LIB_DIR/terminal.sh"
source "$LIB_DIR/locale.sh"
source "$LIB_DIR/nikki.sh"
source "$LIB_DIR/summary.sh"

# 自定义文件输出目录（可通过参数指定）
FILES_DIR="${1:-$FILES_DIR}"

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

# ==================== 主程序 ====================
main() {
    setup_terminal_tools "$FILES_DIR"
    setup_chinese_locale "$FILES_DIR"
    setup_nikki_dashboard "$FILES_DIR"
    setup_nikki_geodata "$FILES_DIR"
    setup_nikki_feed "$FILES_DIR"
    show_summary "$FILES_DIR"
}

main "$@"
