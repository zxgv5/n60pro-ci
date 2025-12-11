#!/bin/bash

# Remove the default apps
# TARGET_MK_FILE="./include/target.mk"
# sed -i 's/ddns-scripts_aliyun //g' $TARGET_MK_FILE
# sed -i 's/ddns-scripts_dnspod //g' $TARGET_MK_FILE
# sed -i 's/luci-app-ddns //g' $TARGET_MK_FILE
# sed -i 's/luci-app-arpbind //g' $TARGET_MK_FILE
# sed -i 's/luci-app-filetransfer //g' $TARGET_MK_FILE
# sed -i 's/luci-app-vsftpd //g' $TARGET_MK_FILE
# sed -i 's/luci-app-ssr-plus //g' $TARGET_MK_FILE
# sed -i 's/luci-app-vlmcsd //g' $TARGET_MK_FILE
# sed -i 's/luci-app-accesscontrol //g' $TARGET_MK_FILE
# sed -i 's/luci-app-nlbwmon //g' $TARGET_MK_FILE
# sed -i 's/luci-app-wol //g' $TARGET_MK_FILE

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
    # 设置默认值
    local name="${1:-Allow-Wireguard-Inbound}"
    local port="${2:-52077}"
    local proto="${3:-udp}"
    local src="${4:-*}"
    local target="${5:-ACCEPT}"
    local file="${6:-./package/network/config/firewall/files/firewall.config}"
    
    # 支持多个协议（用空格分隔）
    local proto_lines=""
    for p in $proto; do
        proto_lines="${proto_lines}    list proto '$p'
"
    done
    proto_lines="${proto_lines%$'\n'}"  # 移除最后一个换行
    
    cat >> "$file" <<EOF
config rule
    option name '$name'
    option src '$src'
${proto_lines}
    option dest_port '$port'
    option target '$target'
EOF
}

# 添加wireguard防火墙规则
add_firewall_rule "Allow-Wireguard-Inbound" "52077"
# 添加其他规则示例
# add_firewall_rule "Allow-HTTP" "80" "tcp"
# add_firewall_rule "Allow-Multiple-Protocols" "443" "tcp udp"
# add_firewall_rule "Allow-Specific-Source" "22" "tcp" "192.168.1.0/24"
# add_firewall_rule "Custom-Rule" "8080" "tcp" "wan" "REJECT"
# add_firewall_rule "Custom-Path" "9000" "tcp" "*" "ACCEPT" "/path/to/firewall.config"