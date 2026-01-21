#!/bin/bash
# ============================================================
# 通用配置和辅助函数
# ============================================================

# 获取脚本所在目录（lib 目录）
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 获取项目根目录（lib 目录的父目录的父目录）
PROJECT_DIR="$(cd "$LIB_DIR/../.." && pwd)"
SCRIPT_DIR="$PROJECT_DIR/scripts"
CONFIG_DIR="$PROJECT_DIR/config"
BUILD_DIR="$PROJECT_DIR/imagebuilder"
FILES_DIR="$BUILD_DIR/custom-files"
DATA_DIR="$PROJECT_DIR/data"

# 加载软件包配置
if [ -f "$CONFIG_DIR/packages.conf" ]; then
    source "$CONFIG_DIR/packages.conf"
else
    echo "错误: 找不到配置文件 $CONFIG_DIR/packages.conf" >&2
    exit 1
fi
