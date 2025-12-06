#!/bin/bash

# Source include file
. ./scripts/INCLUDE.sh

# Exit on error
set -e

# Display Profile
make info

# VARIABEL
PROFILE=""
PACKAGES=""
MISC=""
EXCLUDED=""

# CORE SYSTEM
PACKAGES+=" libc bash block-mount coreutils-base64 coreutils-sleep coreutils-stat \
curl wget-ssl tar unzip uhttpd uhttpd-mod-ubus \
luci luci-ssl dnsmasq-full dbus libdbus glib2 htop"

# STORAGE & FILESYSTEM
PACKAGES+=" kmod-usb-storage kmod-scsi-core dosfstools fdisk parted losetup resize2fs e2fsprogs"

# ETHERNET & MODEM DRIVERS
PACKAGES+=" kmod-usb-uhci kmod-usb-ohci kmod-usb2 kmod-usb3 usbutils kmod-macvlan kmod-mii kmod-usb-net \
kmod-usb-net-rtl8150 kmod-usb-net-rtl8152 kmod-usb-net-asix kmod-usb-net-asix-ax88179 \
kmod-usb-serial kmod-usb-serial-option kmod-nls-utf8 kmod-usb-serial-wwan \
kmod-usb-serial-qualcomm kmod-usb-serial-sierrawireless kmod-usb-acm kmod-usb-wdm \
kmod-usb-net-rndis kmod-usb-net-cdc-ether kmod-usb-net-cdc-ncm kmod-usb-net-sierrawireless \
kmod-usb-net-qmi-wwan kmod-usb-net-huawei-cdc-ncm kmod-usb-net-cdc-mbim \
uqmi libqmi qmi-utils umbim libmbim mbim-utils luci-proto-qmi \
modemmanager luci-proto-modemmanager luci-proto-ncm usb-modeswitch xmm-modem luci-proto-xmm"

# MODEM TOOLS
PACKAGES+=" atinout modeminfo modemband sms-tool luci-app-modeminfo luci-app-modemband luci-app-sms-tool-js picocom minicom"
PACKAGES+=" modeminfo-serial-dell modeminfo-serial-fibocom modeminfo-serial-sierra modeminfo-serial-tw modeminfo-serial-xmm"

# UTILITIES
PACKAGES+=" luci-app-diskman luci-app-eqosplus ookla-speedtest"
PACKAGES+=" internet-detector internet-detector-mod-modem-restart luci-app-internet-detector luci-app-netmonitor luci-app-3ginfo-lite"

# REMOTE ACCESS & THEMES
PACKAGES+=" tailscale luci-app-tailscale"
PACKAGES+=" luci-theme-rtawrt luci-theme-argon luci-theme-alpha"

# PHP8
PACKAGES+=" php8 php8-cli php8-fastcgi php8-fpm php8-mod-session php8-mod-ctype php8-mod-fileinfo php8-mod-zip php8-mod-iconv php8-mod-mbstring"

# MISC PACKAGES
MISC+=" zoneinfo-core zoneinfo-asia jq httping adb openssh-sftp-server zram-swap screen \
atc-fib-l8x0_gl atc-fib-fm350_gl luci-proto-atc luci-app-mmconfig luci-app-droidnet luci-app-ipinfo \
luci-app-lite-watchdog luci-app-poweroffdevice luci-app-ramfree luci-app-tinyfm luci-app-ttyd"

# VPN TUNNEL
OPENCLASH="coreutils-nohup ipset ip-full libcap libcap-bin ruby ruby-yaml kmod-tun kmod-inet-diag kmod-nft-tproxy luci-app-openclash"
NIKKI="nikki luci-app-nikki"
NEKO="kmod-tun luci-app-neko"
PASSWALL="microsocks dns2socks dns2tcp ipt2socks tcping chinadns-ng xray-core sing-box xray-plugin naiveproxy trojan-plus tuic-client luci-app-passwall"

add_tunnel_packages() {
    local option="$1"
    case "$option" in
        openclash)
            PACKAGES+=" $OPENCLASH"
            ;;
        nikki)
            PACKAGES+=" $NIKKI"
            ;;
        neko)
            PACKAGES+=" $NEKO"
            ;;
        nikki-passwall)
            PACKAGES+=" $NIKKI $PASSWALL"
            ;;
        openclash-nikki)
            PACKAGES+=" $OPENCLASH $NIKKI"
            ;;
        openclash-nikki-passwall)
            PACKAGES+=" $OPENCLASH $NIKKI $PASSWALL"
            ;;
        *)
            # No tunnel specific packages
            ;;
    esac
}

# PROFILE SPECIFIC
configure_profile_packages() {
    local profile_name="$1"

    if [[ "$profile_name" == *"rpi-2"* ]] || [[ "$profile_name" == *"rpi-3"* ]] || [[ "$profile_name" == *"rpi-4"* ]] || [[ "$profile_name" == *"rpi-5"* ]]; then
        PACKAGES+=" kmod-i2c-bcm2835 i2c-tools kmod-i2c-core kmod-i2c-gpio"
    elif [[ "${ARCH_2:-}" == "x86_64" ]]; then
        PACKAGES+=" kmod-iwlwifi iw-full pciutils wireless-tools"
    fi

    if [[ "${TYPE:-}" == "OPHUB" ]] || [[ "${TYPE:-}" == "ULO" ]]; then
        PACKAGES+=" luci-app-amlogic btrfs-progs kmod-fs-btrfs"
        EXCLUDED+=" -procd-ujail"
    fi
}

# RELEASE SPECIFIC
configure_release_packages() {
    EXCLUDED+=" -dnsmasq -wpad-basic -wpad-mini -wpad-basic-wolfssl -wpad-mini-wolfssl"

    if [[ "${BASE:-}" == "openwrt" ]]; then
        MISC+=" wpad-openssl iw iwinfo wireless-regdb kmod-cfg80211 kmod-mac80211 luci-app-temp-status"
    elif [[ "${BASE:-}" == "immortalwrt" ]]; then
        MISC+=" wpad-openssl iw iwinfo wireless-regdb kmod-cfg80211 kmod-mac80211"
        EXCLUDED+=" -cpusage -automount -libustream-openssl -default-settings-chn -luci-i18n-base-zh-cn"
        
        if [[ "${ARCH_2:-}" == "x86_64" ]]; then
            EXCLUDED+=" -kmod-usb-net-rtl8152-vendor"
        fi
    fi
}

# MAIN BUILD
build_firmware() {
    local target_profile="$1"
    local tunnel_option="${2:-}"
    local build_files="files"

    log "INFO" "Starting build for profile '$target_profile' [Tunnel: $tunnel_option]..."

    # Load Profile Specifics
    configure_profile_packages "$target_profile"
    
    # Load Tunnel Packages
    add_tunnel_packages "$tunnel_option"
    
    # Load Base/Release Config
    configure_release_packages

    # PACKAGES + MISC + EXCLUDED    
    make image PROFILE="$target_profile" PACKAGES="$PACKAGES $MISC $EXCLUDED" FILES="$build_files"
    
    local build_status=$?
    if [ "$build_status" -eq 0 ]; then
        log "SUCCESS" "Build completed successfully!"
    else
        log "ERROR" "Build failed with exit code $build_status"
        exit "$build_status"
    fi
}

# Validasi Argumen
if [ -z "${1:-}" ]; then
    echo "ERROR: Profile not specified."
    echo "Usage: $0 <profile> [tunnel_option]"
    echo "Tunnel Options: openclash, nikki, neko, nikki-passwall, openclash-nikki, openclash-nikki-passwall"
    exit 1
fi

# Jalankan log function dummy
if ! command -v log &> /dev/null; then
    log() { echo "[$1] $2"; }
fi

# Running Build
build_firmware "$1" "${2:-}"
