#!/bin/bash

#修改内核为6.12
TARGET_MEDIATEK_MAKEFILE="./target/linux/mediatek/Makefile"
sed -i 's/^\(KERNEL_\(TESTING_\)\?PATCHVER\s*:=\s*\).*/\16.12/' $TARGET_MEDIATEK_MAKEFILE
#  sed -i 's/^\(KERNEL_\(TESTING_\)\?PATCHVER\s*:=\s*\).*/\16.12/' $TARGET_MEDIATEK_MAKEFILE

# 移除默认插件，修改为如下实现
TARGET_MK_FILE="./include/target.mk"
sed -i -e 's/ddns-scripts_aliyun //g' \
       -e 's/ddns-scripts_dnspod //g' \
       -e 's/luci-app-\(ddns\|arpbind\|filetransfer\|vsftpd\|ssr-plus\|vlmcsd\|accesscontrol\|nlbwmon\|wol\) //g' \
       $TARGET_MK_FILE

#移除luci-app-attendedsysupgrade
sed -i "/attendedsysupgrade/d" $(find ./feeds/luci/collections/ -type f -name "Makefile")
#修改immortalwrt.lan关联IP
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$LEDE_IP/g" $(find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js")

CONFIG_GENERATE="./package/base-files/files/bin/config_generate"
MAC80211_SH="./package/kernel/mac80211/files/lib/wifi/mac80211.sh"
# 修改主机名
modify_hostname() {
    sed -i "s/set system\.@system\[-1\]\.hostname='LEDE'/set system\.@system[-1]\.hostname='$LEDE_NAME'/g" "$CONFIG_GENERATE"
    
    # 检查board.json中的主机名设置（如果存在）
    sed -i '/json_get_var hostname hostname/,/uci -q set "system\.@system\[-1\]\.hostname=\$hostname"/{
        /uci -q set "system\.@system\[-1\]\.hostname=\$hostname"/{
            a\                        uci -q set "system.@system[-1].hostname=$LEDE_NAME"
        }
    }' "$CONFIG_GENERATE"
}
# 修改默认LAN口IP地址
modify_lan_ip() {
    # 修改generate_network函数中lan口的默认IP
    sed -i "s/ipad=\${ipaddr:-\"192\.168\.1\.1\"}/ipad=\${ipaddr:-\"$LEDE_IP\"}/g" "$CONFIG_GENERATE"
    
    # 修改静态网络配置中的LAN口IP（如果有其他地方的默认设置）
    sed -i "/case \"\$1\" in/,/lan) ipad=\${ipaddr:-\"$LEDE_IP\"} ;;/{
        s/lan) ipad=\${ipaddr:-\"192\.168\.1\.1\"} ;;/lan) ipad=\${ipaddr:-\"$LEDE_IP\"} ;;/g
    }" "$CONFIG_GENERATE"
    
    # 子网掩码
    # sed -i "s/netm=\${netmask:-\"255\.255\.255\.0\"}/netm=\${netmask:-\"$LEDE_NETMASK\"}/g" "$CONFIG_GENERATE"
}
# 修改WiFi配置
modify_wifi_config() {
    # 修改mac80211.sh中的WiFi配置
    # 修改SSID
    sed -i "s/set wireless\.default_radio\${devidx}\.ssid=LEDE/set wireless\.default_radio\${devidx}\.ssid=$LEDE_WIFI_SSID/g" "$MAC80211_SH"
    
    # 修改加密方式
    sed -i "s/set wireless\.default_radio\${devidx}\.encryption=none/set wireless\.default_radio\${devidx}\.encryption=$LEDE_WIFI_ENCRYPT/g" "$MAC80211_SH"
    
    # 添加WiFi密码设置
    if [ "$LEDE_WIFI_ENCRYPT" != "none" ]; then
        # 检查是否已经存在密码设置
        if ! grep -q "set wireless.default_radio\${devidx}.key" "$MAC80211_SH"; then
            # 在encryption行后添加密码设置
            sed -i "/set wireless\.default_radio\${devidx}\.encryption=$LEDE_WIFI_ENCRYPT/a\\                        set wireless.default_radio\${devidx}.key='$LEDE_WIFI_PASSWORD'" "$MAC80211_SH"
        else
            # 如果已存在密码设置，则修改它
            sed -i "s/set wireless\.default_radio\${devidx}\.key='.*'/set wireless\.default_radio\${devidx}\.key='$LEDE_WIFI_PASSWORD'/g" "$MAC80211_SH"
        fi
    fi
}
# 可选：修改WiFi国家代码（可选）
# modify_wifi_country() {
#     COUNTRY_CODE="CN"  # 修改为您的国家代码，如CN、US、UK等
#     echo "修改WiFi国家代码为: $COUNTRY_CODE"
#     sed -i "s/set wireless\.radio\${devidx}\.country=US/set wireless\.radio\${devidx}\.country=$COUNTRY_CODE/g" "$MAC80211_SH"
# }
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

# 修改主机名
modify_hostname
# 修改默认LAN口IP地址
modify_lan_ip
# 修改WiFi配置
modify_wifi_config
# 添加wireguard防火墙规则
add_firewall_rule "Allow-Wireguard-Inbound" "52077"

# 添加wireguard防火墙规则
# cat >> ./package/network/config/firewall/files/firewall.config <<EOF
# config rule
#     option name 'Allow-Wireguard-Inbound'
#     option src '*'
#     list proto 'udp'
#     option dest_port '52077'
#     option target 'ACCEPT'
# EOF

# 添加其他规则示例
# add_firewall_rule "Allow-HTTP" "80" "tcp"
# add_firewall_rule "Allow-Multiple-Protocols" "443" "tcp udp"
# add_firewall_rule "Allow-Specific-Source" "22" "tcp" "192.168.1.0/24"
# add_firewall_rule "Custom-Rule" "8080" "tcp" "wan" "REJECT"
# add_firewall_rule "Custom-Path" "9000" "tcp" "*" "ACCEPT" "/path/to/firewall.config"