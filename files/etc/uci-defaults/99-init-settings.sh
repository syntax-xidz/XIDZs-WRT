#!/bin/sh

LOG_FILE="/root/setup-xidzswrt.log"
exec > "$LOG_FILE" 2>&1

SYSTEM_JS="/www/luci-static/resources/view/status/include/10_system.js"
PORTS_JS="/www/luci-static/resources/view/status/include/29_ports.js"
NEW_PORTS_JS="/www/luci-static/resources/view/status/include/11_ports.js"
RELEASE_FILE="/etc/openwrt_release"
TTYD_JSON="/usr/share/luci/menu.d/luci-app-ttyd.json"
TEMP_JS="/www/luci-static/resources/view/status/include/27_temperature.js"
NEW_TEMP_JS="/www/luci-static/resources/view/status/include/15_temperature.js"
RC_LOCAL="/etc/rc.local"
CRONTAB_ROOT="/etc/crontabs/root"
USB_MODE="/etc/usb-mode.json"
OPKG_CONF="/etc/opkg.conf"
PROFILE="/etc/profile"
CLASH_META="/etc/openclash/core/clash_meta"
O_COUNTRY_MMDB="/etc/openclash/Country.mmdb"
N_COUNTRY_MMDB="/etc/nikki/run/Country.mmdb"
OC_GEOIP="/etc/openclash/GeoIP.dat"
OC_GEOSITE="/etc/openclash/GeoSite.dat"
NIKKI_GEOIP="/etc/nikki/run/GeoIP.dat"
NIKKI_GEOSITE="/etc/nikki/run/GeoSite.dat"
PHP_INI="/etc/php.ini"
PHP_INI_BAK="/etc/php.ini.bak"
VNSTAT_CONF="/etc/vnstat.conf"
HAT_WWAN="/etc/hotplug.d/usb/23-wwan_hat"
HAT_WIFI="/etc/hotplug.d/usb/99-wifi_hat"
ISSUE="/etc/init.d/issue"
ARGON_CONF="/usr/share/ucode/luci/template/themes/argon/header.ut"
RTA_CONF="/usr/lib/lua/luci/view/themes/rtawrt/header.htm"
ALPHA_CONF="/etc/config/alpha"

# Executable script
INSTALL2_SH="/root/install2.sh"
TTY_SH="/root/tty.sh"
QUENX_SH="/root/quenx.sh"
FREE_SH="/sbin/free.sh"
JAM="/sbin/jam"
PING_SH="/sbin/ping.sh"
REPAIR_RO="/sbin/repair_ro"
XDEV="/usr/bin/xdev"
XIDZ="/usr/bin/xidz"
XTUN="/usr/bin/xtun"
X_GPIO="/usr/bin/x-gpio"
X_GPIO_LED="/usr/bin/x-gpioled"

# Detect system type
echo "Checking system release..."
if grep -q "ImmortalWrt" /etc/openwrt_release; then
    sed -i 's/\(DISTRIB_DESCRIPTION='\''ImmortalWrt [0-9]*\.[0-9]*\.[0-9]*\).*'\''/\1'\''/g' "$RELEASE_FILE"
    sed -i 's|system/ttyd|services/ttyd|g' "$TTYD_JSON"
    BRANCH_VERSION=$(grep 'DISTRIB_DESCRIPTION=' /etc/openwrt_release | awk -F"'" '{print $2}')
    echo "ImmortalWrt detected: $BRANCH_VERSION"
elif grep -q "OpenWrt" /etc/openwrt_release; then
    sed -i 's/\(DISTRIB_DESCRIPTION='\''OpenWrt [0-9]*\.[0-9]*\.[0-9]*\).*'\''/\1'\''/g' "$RELEASE_FILE"
    mv "$TEMP_JS" "$NEW_TEMP_JS"
    BRANCH_VERSION=$(grep 'DISTRIB_DESCRIPTION=' /etc/openwrt_release | awk -F"'" '{print $2}')
    echo "OpenWrt detected: $BRANCH_VERSION"
else
    echo "Unknown system release"
fi

# Configure package and add custom repo
echo "Disabling OPKG signature checking..."
sed -i 's/option check_signature/# option check_signature/g' "$OPKG_CONF"

echo "Adding custom repository..."
ARCH=$(grep "OPENWRT_ARCH" /etc/os-release | awk -F '"' '{print $2}')
echo "src/gz custom_packages https://dl.openwrt.ai/latest/packages/$ARCH/kiddin9" >> /etc/opkg/customfeeds.conf

# Basic system configuration
echo "Setting root password..."
(echo "access"; sleep 2; echo "access") | passwd > /dev/null

echo "Configuring hostname and timezone..."
uci set system.@system[0].hostname='XIDZs-WRT'
uci set system.@system[0].timezone='WIB-7'
uci set system.@system[0].zonename='Asia/Jakarta'
uci delete system.ntp.server
uci add_list system.ntp.server='pool.ntp.org'
uci add_list system.ntp.server='id.pool.ntp.org'
uci add_list system.ntp.server='time.google.com'
uci commit system

echo "Setting default language..."
uci set luci.@core[0].lang='en'
uci commit luci

echo "Setting default theme..."
uci set luci.main.mediaurlbase='/luci-static/argon'
uci commit luci

# interface detection and configuration
echo "Detecting interfaces..."

# variables
WAN_DEVICE=""
WAN_PROTO="dhcp"

# interface detection
if [ -e /sys/class/net/wwan0 ]; then
    echo "wwan0 found - use ModemManager"
    WAN_DEVICE="wwan0"
    WAN_PROTO="modemmanager"
    
elif [ -e /sys/class/net/usb0 ]; then
    echo "usb0 found - use DHCP"
    WAN_DEVICE="usb0"
    WAN_PROTO="dhcp"

elif [ -e /sys/class/net/eth1 ]; then
    echo "eth1 found - use DHCP"
    WAN_DEVICE="eth1"
    WAN_PROTO="dhcp"
    
elif ls /sys/devices/*/usb*/*/tty/ttyUSB* >/dev/null 2>&1 || ls /sys/devices/*/usb*/*/tty/ttyACM* >/dev/null 2>&1; then
    echo "wwan0 modem found - use ModemManager"
    MODEM_PATH=$(find /sys/devices -name "ttyUSB*" -o -name "ttyACM*" 2>/dev/null | head -1 | sed 's|/tty/.*||')
    if [ -n "$MODEM_PATH" ]; then
        echo "Modem path: $MODEM_PATH"
        WAN_DEVICE="$MODEM_PATH"
        WAN_PROTO="modemmanager"
    else
        echo "Path not found - fallback to usb0"
        WAN_DEVICE="usb0"
        WAN_PROTO="dhcp"
    fi
    
else
    echo "No interface detected - default usb0"
    WAN_DEVICE="usb0"
    WAN_PROTO="dhcp"
fi

# Configure WAN interface
echo "Config WAN: $WAN_DEVICE"
uci set network.wan=interface
uci set network.wan.proto="$WAN_PROTO"
uci set network.wan.device="$WAN_DEVICE"

# Modemmanager specific
if [ "$WAN_PROTO" = "modemmanager" ]; then
    uci set network.wan.apn='internet'
    uci set network.wan.auth='none'
    uci set network.wan.iptype='ipv4'
    uci set network.wan.force_connection='1'
fi

uci delete network.wan6 2>/dev/null
uci commit network

# Configure firewall
echo "Configuring firewall zones..."
uci set firewall.@zone[1].network='wan'
uci commit firewall

# Wireless configuration
echo "Configuring wireless..."
uci set wireless.@wifi-device[0].disabled='0'
uci set wireless.@wifi-iface[0].disabled='0'
uci set wireless.@wifi-iface[0].mode='ap'
uci set wireless.@wifi-iface[0].encryption='psk2'
uci set wireless.@wifi-iface[0].key='XIDZs2025'
uci set wireless.@wifi-device[0].country='ID'

if grep -q "Raspberry Pi 4\|Raspberry Pi 3" /proc/cpuinfo 2>/dev/null; then
    echo "Raspberry Pi detected - configuring 5GHz WiFi"
    uci set wireless.@wifi-iface[0].ssid='XIDZs_5G'
    uci set wireless.@wifi-device[0].channel='149'
    uci set wireless.@wifi-device[0].htmode='VHT80'
else
    echo "Generic device - configuring 2.4GHz WiFi"
    uci set wireless.@wifi-iface[0].ssid='XIDZs'
    uci set wireless.@wifi-device[0].channel='1'
    uci set wireless.@wifi-device[0].htmode='HT20'
fi

uci commit wireless

# WiFi startup fix for RPi
if iw dev 2>/dev/null | grep -q Interface; then
    if grep -q "Raspberry Pi 4\|Raspberry Pi 3" /proc/cpuinfo 2>/dev/null; then
        echo "Adding WiFi startup scripts for RPi"
        if ! grep -q "wifi up" /etc/rc.local; then
            sed -i '/exit 0/i # WiFi startup for RPi' "$RC_LOCAL"
            sed -i '/exit 0/i sleep 10 && wifi up' "$RC_LOCAL"
        fi
        if ! grep -q "wifi up" /etc/crontabs/root; then
            echo "# WiFi restart cron" >> /etc/crontabs/root
            echo "0 */12 * * * wifi down && sleep 5 && wifi up" >> /etc/crontabs/root
        fi
    fi
fi


# remove me909s and dw5821e
echo "Removing USB modeswitch entries..."
sed -i -e '/12d1:15c1/,+5d' -e '/413c:81d7/,+5d' "$USB_MODE"

echo "Disabling XMM-Modem..."
uci set xmm-modem.@xmm-modem[0].enable='0' 2>/dev/null
uci commit xmm-modem 2>/dev/null

# ttyd and tinyfm setup
echo "Configuring TTYD..."
uci set ttyd.@ttyd[0].command='/bin/bash --login'
uci commit ttyd

echo "Setting up TinyFM..."
ln -sf / /www/tinyfm/rootfs

# UI customizations
echo "Modifying UI elements..."
sed -i "s#_('Firmware Version'),(L.isObject(boardinfo.release)?boardinfo.release.description+' / ':'')+(luciversion||''),#_('Firmware Version'),(L.isObject(boardinfo.release)?boardinfo.release.description+' | xidz_x':''),#g" "$SYSTEM_JS"
sed -i -E 's/icons\/port_%s\.(svg|png)/icons\/port_%s.gif/g' "$PORTS_JS"
mv "$PORTS_JS" "$NEW_PORTS_JS"

# Set file permissions
echo "Sett file permissions..."
EXEC_FILES="$FREE_SH $JAM $PING_SH $REPAIR_RO $XDEV $XIDZ $XTUN $INSTALL2_SH $TTY_SH $QUENX_SH $ISSUE"
chmod +x $EXEC_FILES 2>/dev/null

# System customizations
echo "Applying system.."
sed -i -e 's/\[ -f \/etc\/banner \] && cat \/etc\/banner/#&/' -e 's/\[ -n \"\$FAILSAFE\" \] && cat \/etc\/banner.failsafe/& || \/usr\/bin\/xidz/' "$PROFILE"
"$ISSUE" enable

# Add startup scripts
echo "Adding custom startup scripts..."
sed -i '/exit 0/i #/etc/init.d/openclash restart' "$RC_LOCAL"
sed -i '/exit 0/i #sleep 5 && /sbin/free.sh' "$RC_LOCAL"
sed -i '/exit 0/i #/sbin/jam bug.com' "$RC_LOCAL"

# Device-specific configuration
echo "Checking device Model..."
if grep -q "OrangePi Zero3" /proc/device-tree/model 2>/dev/null; then
    echo "OrangePi Zero3 detected"
    ORANGEPI_FILES="$HAT_WWAN $HAT_WIFI"
    chmod +x $ORANGEPI_FILES 2>/dev/null
else
    echo "Generic device detected"
    ORANGEPI_CLEANUP_FILES="$HAT_WIFI $HAT_WWAN"
    rm -f $ORANGEPI_CLEANUP_FILES
fi

echo "Checking for Devices Amlogic..."
if opkg list-installed | grep -q luci-app-amlogic 2>/dev/null; then
    echo "Devices Amlogic detected"
    sed -i '/exit 0/i #sleep 5 && /usr/bin/x-gpio -r' "$RC_LOCAL"
    AMLOGIC_FILES="$X_GPIO $X_GPIO_LED"
    chmod +x $AMLOGIC_FILES 2>/dev/null
else
    echo "Devices Amlogic not detected"
    AMLOGIC_CLEANUP_FILES="$X_GPIO $X_GPIO_LED"
    rm -f $AMLOGIC_CLEANUP_FILES
fi

echo "Running quenx script..."
"$QUENX_SH"

echo "Running TTY script..."
"$TTY_SH"

# Execute scripts
echo "Running install2 script..."
"$INSTALL2_SH"

# Tunnel configuration
echo "Checking tunnel.."
for pkg in luci-app-openclash luci-app-nikki luci-app-passwall; do
    if opkg list-installed | grep -qw "$pkg" 2>/dev/null; then
        echo "$pkg detected - configuring"
        
        case "$pkg" in
            luci-app-openclash)
                echo "Configuring OpenClash"
                OPENCLASH_FILES="$CLASH_META $O_COUNTRY_MMDB $OC_GEOIP $OC_GEOSITE"
                chmod +x $OPENCLASH_FILES 2>/dev/null
                
                # Symbolic links
                ln -sf /etc/openclash/history/quenx.db /etc/openclash/cache.db
                ln -sf /etc/openclash/core/clash_meta /etc/openclash/clash
                
                rm -f /etc/config/openclash    
                mv /etc/config/openclash1 /etc/config/openclash
                
                sed -i '103,105s/.*/<\!-- & -->/' "$RTA_CONF"
                sed -i '144s/.*/<\!-- & -->/' "$ARGON_CONF"
                sed -i "88s/'Enable'/'Disable'/" "$ALPHA_CONF"
                ;;
                
            luci-app-nikki)
                echo "Configuring Nikki"
                NIKKI_FILES="$NIKKI_GEOIP $NIKKI_GEOSITE $N_COUNTRY_MMDB"
                chmod +x $NIKKI_FILES 2>/dev/null
                
                sed -i '115,117s/.*/<\!-- & -->/' "$RTA_CONF"
                sed -i '146s/.*/<\!-- & -->/' "$ARGON_CONF"
                sed -i "40s/'Enable'/'Disable'/" "$ALPHA_CONF"
                ;;
                
            luci-app-passwall)
                echo "Configuring Passwall"
                sed -i '112,114s/.*/<\!-- & -->/' "$RTA_CONF"
                sed -i '147s/.*/<\!-- & -->/' "$ARGON_CONF"
                sed -i "72s/'Enable'/'Disable'/" "$ALPHA_CONF"
                ;;
        esac
        
    else
        echo "$pkg not found - cleaning up"
        
        case "$pkg" in
            luci-app-openclash)
                OPENCLASH_CLEANUP_FILES="/etc/config/openclash1"
                OPENCLASH_CLEANUP_DIRS="/etc/openclash"
                rm -f $OPENCLASH_CLEANUP_FILES
                rm -rf $OPENCLASH_CLEANUP_DIRS
                
                sed -i '118,120s/.*/<\!-- & -->/' "$RTA_CONF"
                sed -i '149s/.*/<\!-- & -->/' "$ARGON_CONF"
                sed -i "104s/'Enable'/'Disable'/" "$ALPHA_CONF"
                ;;
                
            luci-app-nikki)
                NIKKI_CLEANUP_DIRS="/etc/nikki"
                rm -rf $NIKKI_CLEANUP_DIRS
                
                sed -i '121,123s/.*/<\!-- & -->/' "$RTA_CONF"
                sed -i '150s/.*/<\!-- & -->/' "$ARGON_CONF"
                sed -i "120s/'Enable'/'Disable'/" "$ALPHA_CONF"
                ;;
                
            luci-app-passwall)
                PASSWALL_CLEANUP_FILES="/etc/config/passwall"
                rm -f $PASSWALL_CLEANUP_FILES
                
                sed -i '124,126s/.*/<\!-- & -->/' "$RTA_CONF"
                sed -i '151s/.*/<\!-- & -->/' "$ARGON_CONF"
                sed -i "136s/'Enable'/'Disable'/" "$ALPHA_CONF"
                ;;
        esac
    fi
done

# Web server configuration
echo "Configuring web server and PHP..."
uci set uhttpd.main.ubus_prefix='/ubus'
uci set uhttpd.main.interpreter='.php=/usr/bin/php-cgi'
uci set uhttpd.main.index_page='cgi-bin/luci'
uci add_list uhttpd.main.index_page='index.html'
uci add_list uhttpd.main.index_page='index.php'
uci commit uhttpd

cp /etc/php.ini "$PHP_INI_BAK"
sed -i 's|^memory_limit = .*|memory_limit = 128M|g' "$PHP_INI"
sed -i 's|^max_execution_time = .*|max_execution_time = 60|g' "$PHP_INI"
sed -i 's|^display_errors = .*|display_errors = Off|g' "$PHP_INI"
sed -i 's|^;*date\.timezone =.*|date.timezone = Asia/Jakarta|g' "$PHP_INI"

ln -sf /usr/lib/php8

# Final cleanup
echo "Syncing and cleaning up..."
sync
rm -rf /etc/uci-defaults/$(basename "$0")

echo "Setup complete!"

exit 0