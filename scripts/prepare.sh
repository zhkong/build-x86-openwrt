###
# @Author: zhkong
# @Date: 2023-07-25 17:07:02
 # @LastEditors: zhkong
 # @LastEditTime: 2025-11-15 23:58:31
 # @FilePath: /build-x86-openwrt/scripts/prepare.sh
###

# get latest openwrt tag
LATEST_TAG=$(curl -s https://api.github.com/repos/openwrt/openwrt/releases/latest | grep 'tag_name' | cut -d\" -f4)
git clone https://github.com/openwrt/openwrt.git -b $LATEST_TAG --single-branch openwrt --depth 1
cd openwrt

## openwrt-nikki
# echo "src-git nikki https://github.com/nikkinikki-org/OpenWrt-nikki.git;main" >> feeds.conf.default

## openclash
git clone https://github.com/vernesong/OpenClash.git --single-branch --depth 1 package/new/luci-app-openclash
bash ../scripts/download-openclash-core.sh

## argon theme
git clone https://github.com/jerrykuku/luci-theme-argon.git --single-branch --depth 1 package/new/luci-theme-argon

# 更新 Feeds
./scripts/feeds update -a
./scripts/feeds install -a

# 增加 oh-my-zsh
bash ../scripts/preset-terminal-tools.sh

# config file
cp ../config/x86.config .config
make defconfig

cp ../files ./

rm -rf temp

# # 编译固件
# make download -j$(nproc)
# make -j$(nproc) || make -j1 V=s
