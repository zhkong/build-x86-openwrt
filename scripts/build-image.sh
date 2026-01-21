#!/bin/bash
# ============================================================
# ImmortalWrt ImageBuilder 自动构建脚本
# 用于 x86_64 平台
# 功能：使用预编译的 ImageBuilder 快速构建自定义固件
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

# 加载功能模块
source "$LIB_DIR/common.sh"
source "$LIB_DIR/version.sh"
source "$LIB_DIR/download.sh"
source "$LIB_DIR/build.sh"

# ==================== 主程序 ====================
main() {
    echo "=============================================="
    echo "  ImmortalWrt ImageBuilder 自动构建脚本"
    echo "  目标平台: x86_64"
    echo "=============================================="
    echo ""
    
    # 检查依赖
    for cmd in curl tar git make; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "错误: 缺少依赖 '$cmd'"
            exit 1
        fi
    done
    
    # 检查 zstd (可选)
    if ! command -v unzstd &> /dev/null; then
        echo "警告: 未安装 zstd，将尝试使用 .tar.xz 格式"
    fi
    
    # 检查配置文件
    if [ ! -f "$CONFIG_DIR/packages.conf" ]; then
        echo "错误: 找不到配置文件 $CONFIG_DIR/packages.conf"
        exit 1
    fi
    
    # 获取版本
    VERSION=$(get_immortalwrt_version)
    echo "ImmortalWrt 版本: $VERSION"
    echo ""
    
    # 下载 ImageBuilder
    IMAGEBUILDER_DIR=$(download_imagebuilder "$VERSION")
    echo "ImageBuilder 目录: $IMAGEBUILDER_DIR"
    echo ""
    
    # 创建自定义文件
    echo "创建自定义文件..."
    bash "$SCRIPT_DIR/setup-imagebuilder-files.sh" "$FILES_DIR"
    echo ""
    
    # 构建固件
    build_firmware "$IMAGEBUILDER_DIR" "$VERSION"
}

# 运行主程序
main "$@"
