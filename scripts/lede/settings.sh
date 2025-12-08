#!/bin/bash

# Remove the default apps
TARGET_MK_FILE="./include/target.mk"
sed -i 's/ddns-scripts_aliyun //g' $TARGET_MK_FILE
sed -i 's/ddns-scripts_dnspod //g' $TARGET_MK_FILE
sed -i 's/luci-app-ddns //g' $TARGET_MK_FILE
sed -i 's/luci-app-arpbind //g' $TARGET_MK_FILE
sed -i 's/luci-app-filetransfer //g' $TARGET_MK_FILE
sed -i 's/luci-app-vsftpd //g' $TARGET_MK_FILE
sed -i 's/luci-app-ssr-plus //g' $TARGET_MK_FILE
sed -i 's/luci-app-vlmcsd //g' $TARGET_MK_FILE
sed -i 's/luci-app-accesscontrol //g' $TARGET_MK_FILE
sed -i 's/luci-app-nlbwmon //g' $TARGET_MK_FILE
sed -i 's/luci-app-wol //g' $TARGET_MK_FILE

#移除luci-app-attendedsysupgrade
sed -i "/attendedsysupgrade/d" $(find ./feeds/luci/collections/ -type f -name "Makefile")
#修改immortalwrt.lan关联IP
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$LEDE_IP/g" $(find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js")

WIFI_FILE="./package/kernel/mac80211/files/lib/wifi/mac80211.sh"

#修改WIFI名称
sed -i "s/LEDE/$LEDE_SSID/g" $WIFI_FILE
#修改WIFI加密
#sed -i "s/encryption=.*/encryption='psk2+ccmp'/g" $WIFI_FILE

CFG_FILE="./package/base-files/files/bin/config_generate"
#修改默认IP地址
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$LEDE_IP/g" $CFG_FILE
#修改默认主机名
sed -i "s/hostname='.*'/hostname='$LEDE_NAME'/g" $CFG_FILE

#添加wireguard防火墙规则
cat >> ./package/network/config/firewall/files/firewall.config <<EOF
config rule
    option name 'Allow-Wireguard-Inbound'
    option src '*'
    list proto 'udp'
    option dest_port '52077'
    option target 'ACCEPT'
EOF