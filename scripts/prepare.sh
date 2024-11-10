###
# @Author: zhkong
# @Date: 2023-07-25 17:07:02
 # @LastEditors: zhkong
 # @LastEditTime: 2024-11-10 17:21:21
 # @FilePath: /build-x86-openwrt/scripts/prepare.sh
###

# get latest openwrt tag
LATEST_TAG=$(curl -s https://api.github.com/repos/openwrt/openwrt/releases/latest | grep 'tag_name' | cut -d\" -f4)
git clone https://github.com/openwrt/openwrt.git -b $LATEST_TAG --single-branch openwrt --depth 1
cd openwrt

# 更新 Feeds
./scripts/feeds update -a
./scripts/feeds install -a

# 添加第三方软件包
## openclash
git clone https://github.com/vernesong/OpenClash.git --single-branch --depth 1 package/new/luci-openclash
bash ../scripts/download-openclash-core.sh

## argon theme
git clone https://github.com/jerrykuku/luci-theme-argon.git --single-branch --depth 1 package/new/luci-theme-argon

## KMS激活
mv temp/luci/applications/luci-app-vlmcsd package/new/luci-app-vlmcsd
mv temp/packages/net/vlmcsd package/new/vlmcsd
# edit package/new/luci-app-vlmcsd/Makefile
sed -i 's/..\/..\/luci.mk/$(TOPDIR)\/feeds\/luci\/luci.mk/g' package/new/luci-app-vlmcsd/Makefile

## MOSDNS
# remove v2ray-geodata package from feeds (openwrt-22.03 & master)
rm -rf feeds/packages/net/v2ray-geodata
git clone https://github.com/sbwml/luci-app-mosdns -b v5 package/mosdns
git clone https://github.com/sbwml/v2ray-geodata package/v2ray-geodata


# rm -rf feeds/luci/modules/luci-base
# rm -rf feeds/luci/modules/luci-mod-status
# rm -rf feeds/packages/utils/coremark
# rm -rf package/emortal/default-settings

# mv temp/luci/modules/luci-base feeds/luci/modules/luci-base
# mv temp/luci/modules/luci-mod-status feeds/luci/modules/luci-mod-status
# mv temp/packages/utils/coremark package/new/coremark
# mv temp/immortalwrt/package/emortal/default-settings package/new/default-settings

# 增加 oh-my-zsh
bash ../scripts/preset-terminal-tools.sh

# config file
# cp ../config/x86 .config
# make defconfig

rm -rf temp

# # 编译固件
# make download -j$(nproc)
# make -j$(nproc) || make -j1 V=s
