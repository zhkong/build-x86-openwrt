#!/bin/bash
# ============================================================
# ImmortalWrt 版本获取功能
# ============================================================

# 加载通用配置
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# ==================== 获取 ImmortalWrt 版本 ====================
get_immortalwrt_version() {
    local version=""
    
    # 从环境变量或文件获取版本
    if [ -n "$IMMORTALWRT_TAG" ] && [ "$IMMORTALWRT_TAG" != "null" ]; then
        version="$IMMORTALWRT_TAG"
    elif [ -f /tmp/immortalwrt_tag.txt ]; then
        version=$(cat /tmp/immortalwrt_tag.txt)
        # 检查文件内容是否为 null
        if [ "$version" = "null" ] || [ -z "$version" ]; then
            version=""
        fi
    fi
    
    # 如果还是为空，尝试获取最新版本
    if [ -z "$version" ] || [ "$version" = "null" ]; then
        # 获取最新的稳定版本
        # ImmortalWrt 没有 releases，只有 tags，格式类似 v24.10.5 或 24.10.5
        echo "正在获取最新 ImmortalWrt 版本（从 tags）..." >&2
        
        # 从 GitHub API 获取所有 tags，找到最新的版本号格式的 tag
        version=$(curl -s https://api.github.com/repos/immortalwrt/immortalwrt/tags 2>/dev/null | \
            grep -o '"name": *"[^"]*"' | \
            sed 's/"name": *"//;s/"//' | \
            grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+$' | \
            sed 's/^v//' | \
            sort -V | \
            tail -n 1)
        
        # 如果获取不到，尝试从 refs/tags 获取
        if [ -z "$version" ] || [ "$version" = "null" ]; then
            echo "从 tags API 获取失败，尝试从 refs/tags 获取..." >&2
            version=$(curl -s https://api.github.com/repos/immortalwrt/immortalwrt/git/refs/tags 2>/dev/null | \
                grep -o '"ref": *"[^"]*"' | \
                sed 's/"ref": *"refs\/tags\///;s/"//' | \
                grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+$' | \
                sed 's/^v//' | \
                sort -V | \
                tail -n 1)
        fi
        
        # 检查是否为 null
        if [ -z "$version" ] || [ "$version" = "null" ]; then
            # 备用方案：从下载页面获取
            echo "GitHub API 返回无效版本，从下载页面获取..." >&2
            version=$(curl -s https://downloads.immortalwrt.org/releases/ | grep -oP 'href="\K[0-9]+\.[0-9]+\.[0-9]+(?=/")' | sort -V | tail -n 1)
        fi
        
        # 最终备用
        if [ -z "$version" ] || [ "$version" = "null" ]; then
            version="24.10.0"
            echo "警告: 无法获取最新版本，使用默认版本 $version" >&2
        else
            echo "获取到版本: $version" >&2
        fi
    fi
    
    # 清理版本号（移除 'v' 前缀如果存在）
    version="${version#v}"
    
    # 最终验证版本号不为 null
    if [ -z "$version" ] || [ "$version" = "null" ]; then
        echo "错误: 版本号无效 (null 或空)" >&2
        exit 1
    fi
    
    echo "$version"
}
