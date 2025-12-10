#!/bin/bash

#修改内核为6.12
TARGET_MEDIATEK_MAKEFILE="./target/linux/mediatek/Makefile"
sed -i 's/^\(KERNEL_PATCHVER\s*:=\s*\).*/\16.12/' $TARGET_ARM_MAKEFILE

#移除luci-app-attendedsysupgrade
sed -i "/attendedsysupgrade/d" $(find ./feeds/luci/collections/ -type f -name "Makefile")
#修改默认主题
sed -i "s/luci-theme-bootstrap/luci-theme-$PADAVANONLY_THEME/g" $(find ./feeds/luci/collections/ -type f -name "Makefile")
#修改immortalwrt.lan关联IP
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$PADAVANONLY_IP/g" $(find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js")
#添加编译日期标识
sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ $PADAVANONLY_MARK-$PADAVANONLY_DATE')/g" $(find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js")

WIFI_FILE="./package/mtk/applications/mtwifi-cfg/files/mtwifi.sh"
#修改WIFI名称
sed -i "s/ImmortalWrt/$PADAVANONLY_SSID/g" $WIFI_FILE
#修改WIFI加密
sed -i "s/encryption=.*/encryption='psk2+ccmp'/g" $WIFI_FILE
#修改WIFI密码
sed -i "/set wireless.default_\${dev}.encryption='psk2+ccmp'/a \\\t\t\t\t\t\set wireless.default_\${dev}.key='$PADAVANONLY_WORD'" $WIFI_FILE

CFG_FILE="./package/base-files/files/bin/config_generate"
#修改默认IP地址
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$PADAVANONLY_IP/g" $CFG_FILE
#修改默认主机名
sed -i "s/hostname='.*'/hostname='$PADAVANONLY_NAME'/g" $CFG_FILE

#配置文件修改
echo "CONFIG_PACKAGE_luci=y" >> ./.config
echo "CONFIG_LUCI_LANG_zh_Hans=y" >> ./.config
echo "CONFIG_PACKAGE_luci-theme-$PADAVANONLY_THEME=y" >> ./.config
echo "CONFIG_PACKAGE_luci-app-$PADAVANONLY_THEME-config=y" >> ./.config

#手动调整的插件
if [ -n "$PADAVANONLY_PACKAGE" ]; then
    echo -e "$PADAVANONLY_PACKAGE" >> ./.config
fi

#添加wireguard防火墙规则
FIREWALL_FILE="./package/network/config/firewall/files/firewall.config"
cat >> $FIREWALL_FILE <<EOF
config rule
    option name 'Allow-Wireguard-Inbound'
    option src '*'
    list proto 'udp'
    option dest_port '52077'
    option target 'ACCEPT'
EOF