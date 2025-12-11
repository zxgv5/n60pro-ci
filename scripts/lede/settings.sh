#!/bin/bash

# 移除默认插件，修改为如下实现
TARGET_MK_FILE="./include/target.mk"
sed -i -e 's/ddns-scripts_aliyun //g' \
       -e 's/ddns-scripts_dnspod //g' \
       -e 's/luci-app-\(ddns\|arpbind\|filetransfer\|vsftpd\|ssr-plus\|vlmcsd\|accesscontrol\|nlbwmon\|wol\) //g' \
       $TARGET_MK_FILE

#修改内核为6.12
TARGET_MEDIATEK_MAKEFILE="./target/linux/mediatek/Makefile"
sed -i 's/^\(KERNEL_\(TESTING_\)\?PATCHVER\s*:=\s*\).*/\16.12/' $TARGET_MEDIATEK_MAKEFILE

#if [ -f "$TARGET_MEDIATEK_MAKEFILE" ]; then
#  sed -i 's/^\(KERNEL_\(TESTING_\)\?PATCHVER\s*:=\s*\).*/\16.12/' $TARGET_MEDIATEK_MAKEFILE
#  echo "Kernel patch versions updated to 6.12!"
#fi

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

# 添加wireguard防火墙规则
# cat >> ./package/network/config/firewall/files/firewall.config <<EOF
# config rule
#     option name 'Allow-Wireguard-Inbound'
#     option src '*'
#     list proto 'udp'
#     option dest_port '52077'
#     option target 'ACCEPT'
# EOF

# 添加防火墙规则
add_firewall_rule() {
    local name="${1:-Allow-Wireguard-Inbound}"
    local port="${2:-52077}"
    local proto="${3:-udp}"
    local src="${4:-*}"
    local target="${5:-ACCEPT}"
    local file="${6:-./package/network/config/firewall/files/firewall.config}"
    
    {
        printf "config rule\n"
        printf "    option name '%s'\n" "$name"
        printf "    option src '%s'\n" "$src"
        
        # 输出协议行
        for p in $proto; do
            [[ -n "$p" ]] && printf "    list proto '%s'\n" "$p"
        done
        
        printf "    option dest_port '%s'\n" "$port"
        printf "    option target '%s'\n" "$target"
    } >> "$file"
}

# 添加wireguard防火墙规则
add_firewall_rule "Allow-Wireguard-Inbound" "52077"
# 添加其他规则示例
# add_firewall_rule "Allow-HTTP" "80" "tcp"
# add_firewall_rule "Allow-Multiple-Protocols" "443" "tcp udp"
# add_firewall_rule "Allow-Specific-Source" "22" "tcp" "192.168.1.0/24"
# add_firewall_rule "Custom-Rule" "8080" "tcp" "wan" "REJECT"
# add_firewall_rule "Custom-Path" "9000" "tcp" "*" "ACCEPT" "/path/to/firewall.config"