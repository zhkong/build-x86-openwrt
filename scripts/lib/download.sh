#!/bin/bash
# ============================================================
# ImageBuilder 下载功能
# ============================================================

# 加载通用配置
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# ==================== 下载 ImageBuilder ====================
download_imagebuilder() {
    local version="$1"
    
    # 清理版本号：移除可能的前缀（v, v., 等）
    version="${version#v}"
    version="${version#v.}"
    
    # 验证版本号不为 null 或空
    if [ -z "$version" ] || [ "$version" = "null" ]; then
        echo "错误: 传入的版本号为 null 或空" >&2
        echo "尝试从下载页面获取可用版本..." >&2
        
        # 从下载页面获取最新的可用版本
        version=$(curl -s "https://downloads.immortalwrt.org/releases/" | grep -oP 'href="\K[0-9]+\.[0-9]+\.[0-9]+(?=/")' | sort -V | tail -n 1)
        
        if [ -z "$version" ] || [ "$version" = "null" ]; then
            version="24.10.0"
            echo "警告: 无法获取版本号，使用默认版本: $version" >&2
        else
            echo "从下载页面获取到可用版本: $version" >&2
        fi
    fi
    
    # 如果版本号包含额外的字符（如 -rc1, -snapshot 等），尝试提取主要版本号
    local clean_version=$(echo "$version" | sed -E 's/(-rc[0-9]+|-snapshot|-dev|-[a-zA-Z0-9]+)$//')
    
    # 检查是否是标准版本号格式（如 24.10.0）
    if ! echo "$clean_version" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
        echo "警告: 版本号格式可能不正确: $version -> $clean_version" >&2
        echo "尝试从下载页面获取可用版本..." >&2
        
        # 从下载页面获取最新的可用版本
        local available_version=$(curl -s "https://downloads.immortalwrt.org/releases/" | grep -oP 'href="\K[0-9]+\.[0-9]+\.[0-9]+(?=/")' | sort -V | tail -n 1)
        
        if [ -n "$available_version" ] && [ "$available_version" != "null" ]; then
            echo "从下载页面获取到可用版本: $available_version" >&2
            clean_version="$available_version"
        else
            echo "无法从下载页面获取版本，使用清理后的版本: $clean_version" >&2
            # 如果清理后的版本还是不对，使用默认版本
            if ! echo "$clean_version" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
                clean_version="24.10.0"
                echo "使用默认版本: $clean_version" >&2
            fi
        fi
    fi
    
    version="$clean_version"
    
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"
    
    echo "==========================================" >&2
    echo "下载 ImmortalWrt ImageBuilder ${version}..." >&2
    echo "目标平台: ${TARGET}/${SUBTARGET}" >&2
    echo "==========================================" >&2
    
    # 先检查版本目录是否存在
    local version_url="https://downloads.immortalwrt.org/releases/${version}/targets/${TARGET}/${SUBTARGET}/"
    echo "检查版本目录: $version_url" >&2
    
    # 尝试列出可用文件（用于调试）
    if curl -s -f "$version_url" > /dev/null 2>&1; then
        echo "版本目录存在，查找 ImageBuilder 文件..." >&2
    else
        echo "警告: 版本目录可能不存在，将直接尝试下载..." >&2
    fi
    
    # 构建可能的文件名
    local base_name="immortalwrt-imagebuilder-${version}-${TARGET}-${SUBTARGET}.Linux-x86_64"
    local filename_zst="${base_name}.tar.zst"
    local filename_xz="${base_name}.tar.xz"
    local url_zst="https://downloads.immortalwrt.org/releases/${version}/targets/${TARGET}/${SUBTARGET}/${filename_zst}"
    local url_xz="https://downloads.immortalwrt.org/releases/${version}/targets/${TARGET}/${SUBTARGET}/${filename_xz}"
    
    local filename=""
    local url=""
    local download_success=false
    
    # 尝试下载 .zst 格式
    if [ ! -f "$filename_zst" ]; then
        echo "尝试下载: $url_zst" >&2
        if curl -L -f -o "$filename_zst" "$url_zst" 2>/dev/null; then
            filename="$filename_zst"
            url="$url_zst"
            download_success=true
            echo "成功下载 .zst 格式文件" >&2
        else
            echo ".zst 格式下载失败 (404 或其他错误)" >&2
        fi
    else
        filename="$filename_zst"
        download_success=true
        echo "ImageBuilder .zst 文件已存在，跳过下载" >&2
    fi
    
    # 如果 .zst 失败，尝试 .xz 格式
    if [ "$download_success" != "true" ]; then
        if [ ! -f "$filename_xz" ]; then
            echo "尝试下载: $url_xz" >&2
            if curl -L -f -o "$filename_xz" "$url_xz" 2>/dev/null; then
                filename="$filename_xz"
                url="$url_xz"
                download_success=true
                echo "成功下载 .xz 格式文件" >&2
            else
                echo ".xz 格式下载失败 (404 或其他错误)" >&2
            fi
        else
            filename="$filename_xz"
            download_success=true
            echo "ImageBuilder .xz 文件已存在，跳过下载" >&2
        fi
    fi
    
    # 如果都失败了，尝试列出目录查看可用文件
    if [ "$download_success" != "true" ]; then
        echo "错误: 无法下载 ImageBuilder" >&2
        echo "尝试的 URL:" >&2
        echo "  - $url_zst" >&2
        echo "  - $url_xz" >&2
        echo "" >&2
        echo "尝试列出目录内容以查找可用文件..." >&2
        curl -s "$version_url" 2>/dev/null | grep -i "imagebuilder" | head -10 >&2 || true
        exit 1
    fi
    
    # 验证文件是否存在且不为空
    if [ ! -f "$filename" ] || [ ! -s "$filename" ]; then
        echo "错误: 下载的文件不存在或为空: $filename" >&2
        exit 1
    fi
    
    # 检测文件实际类型（通过 file 命令或 magic bytes）
    local file_type=""
    if command -v file &> /dev/null; then
        file_type=$(file -b "$filename" 2>/dev/null || echo "")
    fi
    
    # 如果文件类型检测失败，尝试通过文件头判断
    if [ -z "$file_type" ]; then
        local first_bytes=$(head -c 4 "$filename" 2>/dev/null | od -An -tx1 | tr -d ' \n')
        case "$first_bytes" in
            "28b52f"*|"28b5"*) file_type="Zstandard" ;;  # ZST magic: 28 B5 2F FD
            "fd377a"*|"1f8b"*) file_type="xz" ;;         # XZ magic: FD 37 7A 58 或 gzip: 1F 8B
            *) file_type="unknown" ;;
        esac
        echo "通过文件头检测: $first_bytes -> $file_type" >&2
    fi
    
    # 解压
    local extract_dir="immortalwrt-imagebuilder-${version}-${TARGET}-${SUBTARGET}.Linux-x86_64"
    
    # 检查目录是否存在且完整（验证 Makefile 是否存在）
    local need_extract=true
    if [ -d "$extract_dir" ] && [ -f "$extract_dir/Makefile" ]; then
        echo "ImageBuilder 目录已存在且完整，跳过解压" >&2
        need_extract=false
    elif [ -d "$extract_dir" ]; then
        echo "警告: ImageBuilder 目录存在但不完整（缺少 Makefile），将重新解压..." >&2
        rm -rf "$extract_dir"
    fi
    
    if [ "$need_extract" = true ]; then
        echo "解压 ImageBuilder..." >&2
        echo "文件: $filename" >&2
        echo "检测到的文件类型: ${file_type:-unknown}" >&2
        
        local extract_success=false
        
        # 根据文件扩展名和实际类型选择解压方法
        if [[ "$filename" == *.zst ]] || [[ "$file_type" == *"Zstandard"* ]]; then
            # 尝试使用 zstd 解压
            if command -v zstd &> /dev/null; then
                echo "使用 zstd 解压..." >&2
                if zstd -dc "$filename" | tar -xf -; then
                    extract_success=true
                fi
            fi
            
            # 如果 zstd 失败，尝试使用 unzstd
            if [ "$extract_success" != "true" ] && command -v unzstd &> /dev/null; then
                echo "使用 unzstd 解压..." >&2
                if tar --use-compress-program=unzstd -xf "$filename"; then
                    extract_success=true
                fi
            fi
            
            # 如果都失败了，尝试其他格式
            if [ "$extract_success" != "true" ]; then
                echo "警告: .zst 格式解压失败，尝试作为 .tar.xz 处理..." >&2
                if tar -xJf "$filename" 2>/dev/null; then
                    extract_success=true
                elif tar -xf "$filename" 2>/dev/null; then
                    extract_success=true
                fi
            fi
        elif [[ "$filename" == *.xz ]] || [[ "$file_type" == *"xz"* ]]; then
            echo "使用 tar -xJf 解压..." >&2
            if tar -xJf "$filename"; then
                extract_success=true
            elif tar -xf "$filename"; then
                extract_success=true
            fi
        else
            # 尝试通用解压方法
            echo "尝试通用解压方法..." >&2
            if tar -xf "$filename" 2>/dev/null; then
                extract_success=true
            elif tar -xJf "$filename" 2>/dev/null; then
                extract_success=true
            fi
        fi
        
        if [ "$extract_success" != "true" ]; then
            echo "错误: 解压失败" >&2
            echo "文件大小: $(du -h "$filename" | cut -f1)" >&2
            echo "文件类型检测: $file_type" >&2
            echo "请检查文件是否完整或尝试手动下载" >&2
            exit 1
        fi
    fi
    
    # 检查解压后的目录
    if [ ! -d "$extract_dir" ]; then
        echo "错误: 解压后未找到目录: $extract_dir" >&2
        echo "当前目录: $(pwd)" >&2
        echo "目录内容:" >&2
        ls -la >&2
        exit 1
    fi
    
    # 验证关键文件是否存在
    if [ ! -f "$extract_dir/Makefile" ]; then
        echo "错误: 解压后的目录中未找到 Makefile，解压可能不完整" >&2
        echo "目录内容:" >&2
        ls -la "$extract_dir" | head -20 >&2
        exit 1
    fi
    
    echo "ImageBuilder 解压完成，Makefile 验证通过" >&2
    
    # 返回绝对路径
    local abs_path="$BUILD_DIR/$extract_dir"
    if [ -d "$abs_path" ]; then
        # 使用 realpath 或 cd+pwd 获取绝对路径
        if command -v realpath &> /dev/null; then
            abs_path=$(realpath "$abs_path")
        else
            abs_path=$(cd "$abs_path" && pwd)
        fi
    else
        echo "错误: ImageBuilder 目录不存在: $abs_path" >&2
        exit 1
    fi
    
    echo "$abs_path"
}
