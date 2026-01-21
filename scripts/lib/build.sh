#!/bin/bash
# ============================================================
# 固件构建功能
# ============================================================

# 加载通用配置
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# ==================== 构建固件 ====================
build_firmware() {
    local imagebuilder_dir="$1"
    local version="$2"
    
    echo "=========================================="
    echo "开始构建固件..."
    echo "设备: $PROFILE"
    echo "版本: $version"
    echo "=========================================="
    
    # 检查 ImageBuilder 目录是否存在
    if [ ! -d "$imagebuilder_dir" ]; then
        echo "错误: ImageBuilder 目录不存在: $imagebuilder_dir" >&2
        exit 1
    fi
    
    echo "ImageBuilder 目录: $imagebuilder_dir"
    echo "当前工作目录: $(pwd)"
    echo ""
    
    # 切换到 ImageBuilder 目录
    cd "$imagebuilder_dir" || {
        echo "错误: 无法切换到 ImageBuilder 目录: $imagebuilder_dir" >&2
        exit 1
    }
    
    echo "切换后的工作目录: $(pwd)"
    echo "目录内容:"
    ls -la | head -20
    echo ""
    
    # 检查 Makefile 是否存在
    if [ ! -f "Makefile" ]; then
        echo "错误: 在 ImageBuilder 目录中找不到 Makefile" >&2
        echo "当前目录内容:" >&2
        ls -la >&2
        exit 1
    fi
    
    echo "Makefile 存在，继续构建..."
    echo ""
    
    # 配置镜像格式：使用 ext4 文件系统，禁用虚拟化镜像
    echo "优化镜像格式配置..."
    if [ -f ".config" ]; then
        # 移除现有的镜像格式配置
        sed -i '/^CONFIG_QCOW2_IMAGES=/d' .config 2>/dev/null || true
        sed -i '/^CONFIG_VDI_IMAGES=/d' .config 2>/dev/null || true
        sed -i '/^CONFIG_VMDK_IMAGES=/d' .config 2>/dev/null || true
        sed -i '/^CONFIG_VHDX_IMAGES=/d' .config 2>/dev/null || true
        sed -i '/^CONFIG_ISO_IMAGES=/d' .config 2>/dev/null || true
        sed -i '/^CONFIG_TARGET_ROOTFS_EXT4FS=/d' .config 2>/dev/null || true
        sed -i '/^CONFIG_TARGET_ROOTFS_SQUASHFS=/d' .config 2>/dev/null || true
        sed -i '/^CONFIG_GRUB_EFI_IMAGES=/d' .config 2>/dev/null || true
        sed -i '/^CONFIG_TARGET_ROOTFS_TARGZ=/d' .config 2>/dev/null || true
        sed -i '/^# CONFIG_TARGET_ROOTFS_EXT4FS/d' .config 2>/dev/null || true
        sed -i '/^# CONFIG_TARGET_ROOTFS_SQUASHFS/d' .config 2>/dev/null || true
        
        # 添加配置：启用 ext4，禁用 squashfs 和虚拟化镜像
        echo "# CONFIG_QCOW2_IMAGES is not set" >> .config
        echo "# CONFIG_VDI_IMAGES is not set" >> .config
        echo "# CONFIG_VMDK_IMAGES is not set" >> .config
        echo "# CONFIG_VHDX_IMAGES is not set" >> .config
        echo "# CONFIG_ISO_IMAGES is not set" >> .config
        echo "CONFIG_TARGET_ROOTFS_EXT4FS=y" >> .config
        echo "# CONFIG_TARGET_ROOTFS_SQUASHFS is not set" >> .config
        echo "# CONFIG_GRUB_EFI_IMAGES is not set" >> .config
        echo "# CONFIG_TARGET_ROOTFS_TARGZ is not set" >> .config
        
        # 重新生成配置以确保更改生效
        echo "重新生成配置..."
        make defconfig >/dev/null 2>&1 || true
        
        echo "已配置以下格式："
        echo "  - 启用 ext4 文件系统"
        echo "  - 禁用 squashfs 文件系统"
        echo "  - 禁用虚拟化镜像（qcow2, vdi, vmdk, vhdx, iso）"
        echo "  - 禁用 EFI 镜像格式"
        echo "  - 禁用 tar.gz 根文件系统归档"
        echo "只保留：ext4 BIOS 镜像"
    else
        echo "警告: 未找到 .config 文件"
    fi
    
    # 获取软件包列表
    local packages=$(get_all_packages)
    
    echo "软件包: $packages"
    echo ""
    
    # 构建命令
    echo "执行构建命令..."
    echo "PROFILE=$PROFILE"
    echo "PACKAGES=$packages"
    echo "FILES=$FILES_DIR"
    echo "KERNEL_PARTSIZE=64 (MB)"
    echo "ROOTFS_PARTSIZE=500 (MB)"
    echo ""
    
    # 构建镜像（qcow2 已在 .config 中禁用）
    # KERNEL_PARTSIZE: BIOS/内核分区大小（MB）
    # ROOTFS_PARTSIZE: 系统/根文件系统分区大小（MB）
    make image \
        PROFILE="$PROFILE" \
        PACKAGES="$packages" \
        FILES="$FILES_DIR" \
        EXTRA_IMAGE_NAME="custom" \
        KERNEL_PARTSIZE="64" \
        ROOTFS_PARTSIZE="500"
    
    echo ""
    echo "=========================================="
    echo "构建完成！"
    echo "=========================================="
    
    # 显示输出文件
    echo "固件文件位置:"
    ls -lh "$imagebuilder_dir/bin/targets/$TARGET/$SUBTARGET/"*.bin 2>/dev/null || echo "未找到 .bin 文件"
    ls -lh "$imagebuilder_dir/bin/targets/$TARGET/$SUBTARGET/"*.img* 2>/dev/null || echo "未找到 .img 文件"
    
    # 复制到项目输出目录
    mkdir -p "$PROJECT_DIR/output"
    cp -v "$imagebuilder_dir/bin/targets/$TARGET/$SUBTARGET/"*"$PROFILE"* "$PROJECT_DIR/output/" 2>/dev/null || true
    # 复制 sha256sums 文件（如果存在）
    if [ -f "$imagebuilder_dir/bin/targets/$TARGET/$SUBTARGET/sha256sums" ]; then
        cp -v "$imagebuilder_dir/bin/targets/$TARGET/$SUBTARGET/sha256sums" "$PROJECT_DIR/output/" 2>/dev/null || true
    fi
    
    echo ""
    echo "固件已复制到: $PROJECT_DIR/output/"
    ls -lh "$PROJECT_DIR/output/"
}
