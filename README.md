# ImmortalWrt x86_64 固件构建项目

![GitHub Actions](https://img.shields.io/github/actions/workflow/status/zhkong/build-x86-openwrt/build-firmware.yml?label=构建状态&logo=github)
![Latest Release](https://img.shields.io/github/v/release/zhkong/build-x86-openwrt?label=最新版本&logo=github)
![License](https://img.shields.io/github/license/zhkong/build-x86-openwrt?label=许可证)

基于 [ImmortalWrt](https://github.com/immortalwrt/immortalwrt) 的 x86_64 平台固件自动构建项目，使用 ImageBuilder 快速构建定制固件。

## 📋 项目简介

本项目使用 ImmortalWrt 官方发布的 ImageBuilder 工具，自动化构建适用于 x86_64 平台的定制固件。固件专门针对旁路由（网关模式）场景优化，预装了常用软件包和工具。

## ✨ 主要特性

- 🚀 **快速构建**：使用 ImageBuilder 工具，无需完整编译 OpenWrt 源码，构建速度快
- 🤖 **自动化构建**：GitHub Actions 自动检查新版本并构建固件
- 🇨🇳 **中文支持**：预装中文语言包，LuCI 界面全中文
- 🔧 **旁路由优化**：专门为旁路由场景优化，移除不必要的功能
- 📦 **预装软件**：包含 ttyd、Zsh 等常用工具
- ⚡ **精简高效**：移除 WiFi、USB、IPv6 等不需要的功能，固件体积更小

## 🎯 固件特点

### 预装软件包

- **LuCI Web 界面**：完整的 LuCI 管理界面，支持 HTTPS
- **Nikki (OpenWrt-nikki)**：基于 Mihomo 的透明代理工具，支持多种代理协议
- **ttyd**：Web 终端，支持在浏览器中直接操作路由器
- **Zsh + Oh-My-Zsh**：现代化的 Shell 环境，提升命令行体验
- **中文语言包**：LuCI 界面完全中文化

### 已禁用功能

为了减小固件体积并优化性能，以下功能已被禁用：

- ❌ **IPv6**：完全禁用 IPv6 相关功能
- ❌ **WiFi**：移除所有无线网络相关驱动和工具
- ❌ **USB**：移除 USB 设备支持
- ❌ **虚拟化镜像**：仅保留 BIOS 格式的 squashfs 镜像
- ❌ **编程语言**：移除 Python、Ruby、Perl、Node.js 等运行环境
- ❌ **PPP**：移除 PPPoE 等拨号功能（旁路由不需要）
- ❌ **声音/视频**：移除音频和视频相关内核模块

## 📁 项目结构

```
build-x86-openwrt/
├── .github/
│   └── workflows/
│       └── build-firmware.yml    # GitHub Actions 构建工作流
├── config/
│   ├── packages.conf             # 软件包配置文件
│   └── x86.config                # OpenWrt 编译配置文件
├── scripts/
│   ├── build-image.sh            # 主构建脚本
│   ├── setup-imagebuilder-files.sh  # 创建自定义文件脚本
│   ├── fix-argon-css.sh          # 修复 Argon 主题 CSS
│   ├── preset-terminal-tools.sh  # 预设终端工具（已废弃）
│   └── prepare.sh                # 准备脚本
├── files/                        # OpenWrt 文件覆盖目录
│   └── etc/
│       └── config/
│           ├── dhcp              # DHCP 配置
│           ├── network           # 网络配置
│           └── system            # 系统配置
├── data/                         # 数据文件目录
│   └── zsh/                      # Zsh 配置文件
├── imagebuilder/                 # ImageBuilder 工作目录（自动生成）
└── output/                       # 构建输出目录（自动生成）
```

## 🚀 使用方法

### 方法一：GitHub Actions 自动构建（推荐）

1. **Fork 本项目**到你的 GitHub 仓库

2. **手动触发构建**：
   - 进入 `Actions` 标签页
   - 选择 `X86 OpenWrt Build (ImageBuilder)` 工作流
   - 点击 `Run workflow`
   - 可选择输入特定的 ImmortalWrt tag 版本（留空则使用最新版本）

3. **等待构建完成**：
   - 构建完成后，在 `Actions` 页面下载构建产物
   - 或者在 `Releases` 页面下载发布版本

4. **定时构建**：
   - 工作流每天 UTC 时间 02:00 自动检查是否有新版本
   - 如有新版本，将自动触发构建

### 方法二：本地构建

#### 环境要求

- Linux 系统（推荐 Ubuntu 20.04 或更高版本）
- 至少 20GB 可用磁盘空间
- 网络连接（需要下载 ImageBuilder 和软件包）

#### 构建步骤

1. **克隆项目**：
```bash
git clone <your-repo-url>
cd build-x86-openwrt
```

2. **安装依赖**：
```bash
sudo apt-get update
sudo apt-get install -y curl tar zstd git make
```

3. **执行构建**：
```bash
bash ./scripts/build-image.sh
```

4. **获取固件**：
构建完成后，固件文件位于 `output/` 目录中。

#### 构建产物说明

构建完成后，`output/` 目录将包含以下文件：

- `immortalwrt-*-custom-x86-64-generic-squashfs-combined.img.gz`：**推荐使用**，BIOS 启动的完整固件
- `immortalwrt-*-custom-x86-64-generic-squashfs-combined-efi.img.gz`：UEFI 启动的完整固件
- `immortalwrt-*-custom-x86-64-generic-squashfs-rootfs.img.gz`：仅根文件系统镜像
- `immortalwrt-*-custom-x86-64-generic-rootfs.tar.gz`：根文件系统压缩包
- `immortalwrt-*-custom-x86-64-generic.manifest`：已安装软件包列表
- `sha256sums`：文件校验和

## ⚙️ 配置说明

### 修改软件包列表

编辑 `config/packages.conf` 文件：

- `PACKAGES_*`：添加要安装的软件包
- `PACKAGES_DISABLED_*`：添加要移除的软件包（使用 `-` 前缀）

修改后，重新运行构建脚本即可。

### 修改网络配置

编辑 `files/etc/config/network` 文件可以修改默认网络配置：

```bash
config interface 'lan'
    option ipaddr '192.168.1.101'  # 修改为你的旁路由 IP
    option gateway '192.168.1.1'   # 修改为你的主路由 IP
```

### 修改 DHCP 配置

编辑 `files/etc/config/dhcp` 文件可以修改 DHCP 服务配置。

## 🔄 GitHub Actions 工作流说明

工作流文件位于 `.github/workflows/build-firmware.yml`，主要功能：

1. **检查新版本**：自动检查 ImmortalWrt 官方是否有新版本发布
2. **智能构建**：
   - 定时任务：仅在检测到新版本时构建
   - 手动触发：总是构建
   - Push/Watch 事件：总是构建
3. **构建固件**：使用 ImageBuilder 构建定制固件
4. **发布版本**：自动创建 GitHub Release 并上传固件

### 触发条件

- **定时触发**：每天 UTC 02:00 检查新版本
- **手动触发**：在 Actions 页面手动运行
- **代码推送**：每次 push 到仓库时触发
- **Watch 事件**：Star 仓库时触发（如果启用）

## 📝 自定义说明

### 添加自定义文件

将需要嵌入固件的文件放在 `files/` 目录下，目录结构对应 OpenWrt 的根文件系统。

例如：
- `files/etc/config/myconfig` → `/etc/config/myconfig`
- `files/root/.zshrc` → `/root/.zshrc`

### 自定义脚本

可以在 `scripts/setup-imagebuilder-files.sh` 中添加自定义文件的创建逻辑。

### 修改固件版本信息

固件版本信息会自动从 ImmortalWrt 官方版本获取，或通过环境变量 `IMMORTALWRT_TAG` 指定。

## ⚠️ 注意事项

1. **首次启动**：
   - 默认 IP：`192.168.1.101`
   - 默认用户名：`root`
   - 默认密码：**无密码**（首次登录需要设置）

2. **旁路由配置**：
   - 固件已针对旁路由场景优化
   - LAN 接口 DHCP 已禁用（`option ignore '1'`）
   - 建议在 LuCI 中进一步配置防火墙规则

3. **磁盘分区**：
   - 内核分区大小：64 MB
   - 根文件系统分区大小：500 MB

4. **构建时间**：
   - GitHub Actions 构建时间约 10-20 分钟
   - 本地构建时间取决于网络速度和磁盘 I/O

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

本项目遵循 [MIT License](LICENSE)。

## 🙏 致谢

- [ImmortalWrt](https://github.com/immortalwrt/immortalwrt) - 优秀的 OpenWrt 分支
- [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh) - 强大的 Zsh 配置框架

## 📞 支持

如有问题或建议，请提交 [Issue](../../issues)。

---

**注意**：本项目仅供学习交流使用，请遵守相关法律法规。
