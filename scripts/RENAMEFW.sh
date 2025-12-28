#!/bin/bash

. ./scripts/INCLUDE.sh

rename_firmware() {
    echo -e "${STEPS} Renaming firmware files..."

    # Validasi direktori firmware
    local firmware_dir="$GITHUB_WORKSPACE/$WORKING_DIR/compiled_images"
    if [[ ! -d "$firmware_dir" ]]; then
        error_msg "Invalid firmware directory: ${firmware_dir}"
    fi

    # Pindah ke direktori firmware
    cd "${firmware_dir}" || {
       error_msg "Failed to change directory to ${firmware_dir}"
    }

    # Pola pencarian dan penggantian
    local search_replace_patterns=(
        # Format: "search|replace"

        # bcm27xx
        "-bcm27xx-bcm2709-rpi-2-ext4-factory|RaspberryPi_2B-Ext4_Factory"
        "-bcm27xx-bcm2709-rpi-2-ext4-sysupgrade|RaspberryPi_2B-Ext4_Sysupgrade"
        "-bcm27xx-bcm2709-rpi-2-squashfs-factory|RaspberryPi_2B-Squashfs_Factory"
        "-bcm27xx-bcm2709-rpi-2-squashfs-sysupgrade|RaspberryPi_2B-Squashfs_Sysupgrade"
        
        "-bcm27xx-bcm2710-rpi-3-ext4-factory|RaspberryPi_3B-Ext4_Factory"
        "-bcm27xx-bcm2710-rpi-3-ext4-sysupgrade|RaspberryPi_3B-Ext4_Sysupgrade"
        "-bcm27xx-bcm2710-rpi-3-squashfs-factory|RaspberryPi_3B-Squashfs_Factory"
        "-bcm27xx-bcm2710-rpi-3-squashfs-sysupgrade|RaspberryPi_3B-Squashfs_Sysupgrade"

        "-bcm27xx-bcm2711-rpi-4-ext4-factory|RaspberryPi_4B-Ext4_Factory"
        "-bcm27xx-bcm2711-rpi-4-ext4-sysupgrade|RaspberryPi_4B-Ext4_Sysupgrade"
        "-bcm27xx-bcm2711-rpi-4-squashfs-factory|RaspberryPi_4B-Squashfs_Factory"
        "-bcm27xx-bcm2711-rpi-4-squashfs-sysupgrade|RaspberryPi_4B-Squashfs_Sysupgrade"
        
        "-bcm27xx-bcm2712-rpi-5-ext4-factory|RaspberryPi_5-Ext4_Factory"
        "-bcm27xx-bcm2712-rpi-5-ext4-sysupgrade|RaspberryPi_5-Ext4_Sysupgrade"
        "-bcm27xx-bcm2712-rpi-5-squashfs-factory|RaspberryPi_5-Squashfs_Factory"
        "-bcm27xx-bcm2712-rpi-5-squashfs-sysupgrade|RaspberryPi_5-Squashfs_Sysupgrade"
        
        # Allwinner ULO
        "-h5-orangepi-pc2-|OrangePi_PC2"
        "-h5-orangepi-prime-|OrangePi_Prime"
        "-h5-orangepi-zeroplus-|OrangePi_ZeroPlus"
        "-h5-orangepi-zeroplus2-|OrangePi_ZeroPlus2"
        "-h6-orangepi-1plus-|OrangePi_1Plus"
        "-h6-orangepi-3-|OrangePi_3"
        "-h6-orangepi-3lts-|OrangePi_3LTS"
        "-h6-orangepi-lite2-|OrangePi_Lite2"
        "-h616-orangepi-zero2-|OrangePi_Zero2"
        "-h618-orangepi-zero2w-|OrangePi_Zero2W"
        "-h618-orangepi-zero3-|OrangePi_Zero3"
        
        # Rockchip ULO
        "-rk3566-orangepi-3b-|OrangePi_3B"
        "-rk3588s-orangepi-5-|OrangePi_5"
        "-firefly_roc-rk3328-cc-|Firefly-RK3328"
        
        # Xunlong Official
        "-xunlong_orangepi-r1-plus-lts-squashfs-sysupgrade|OrangePi-R1-Plus-LTS-squashfs-sysupgrade"
        "-xunlong_orangepi-r1-plus-lts-ext4-sysupgrade|OrangePi-R1-Plus-LTS-ext4-sysupgrade"
        "-xunlong_orangepi-r1-plus-squashfs-sysupgrade|OrangePi-R1-Plus-squashfs-sysupgrade"
        "-xunlong_orangepi-r1-plus-ext4-sysupgrade|OrangePi-R1-Plus-ext4-sysupgrade" 
        "-xunlong_orangepi-pc2-squashfs-sdcard|OrangePi-Pc2-squashfs-sdcard"
        "-xunlong_orangepi-pc2-ext4-sdcard|OrangePi-Pc2-ext4-sdcard"
        "-xunlong_orangepi-zero-plus-squashfs-sdcard|OrangePi-Zero-Plus-squashfs-sdcard"
        "-xunlong_orangepi-zero-plus-ext4-sdcard|OrangePi-Zero-Plus-ext4-sdcard"
        "-xunlong_orangepi-zero2-squashfs-sdcard|OrangePi-Zero2-squashfs-sdcard"
        "-xunlong_orangepi-zero2-ext4-sdcard|OrangePi-Zero2-ext4-sdcard"   
        "-xunlong_orangepi-zero3-squashfs-sdcard|OrangePi-Zero3-squashfs-sdcard"
        "-xunlong_orangepi-zero3-ext4-sdcard|OrangePi-Zero3-ext4-sdcard"
        
        # friendlyarm Official
        "-friendlyarm_nanopi-r2c-ext4-sysupgrade|Nanopi-R2C-ext4-sysupgrade"
        "-friendlyarm_nanopi-r2c-plus-ext4-sysupgrade|Nanopi-R2C-Plus-ext4-sysupgrade"
        "-friendlyarm_nanopi-r2s-ext4-sysupgrade|Nanopi-R2S-ext4-sysupgrade"
        "-friendlyarm_nanopi-r2s-plus-ext4-sysupgrade|Nanopi-R2S-Plus-ext4-sysupgrade"
        "-friendlyarm_nanopi-r3s-ext4-sysupgrade|Nanopi-R3S-ext4-sysupgrade"
        "-friendlyarm_nanopi-r4s-ext4-sysupgrade|Nanopi-R4S-ext4-sysupgrade"
        "-friendlyarm_nanopi-r5s-ext4-sysupgrade|Nanopi-R5S-ext4-sysupgrade"
        "-friendlyarm_nanopi-r6s-ext4-sysupgrade|Nanopi-R6S-ext4-sysupgrade"
        "-friendlyarm_nanopi-neo2-ext4-sysupgrade|Nanopi-Neo2-ext4-sysupgrade"
        "-friendlyarm_nanopi-neo-plus2-ext4-sysupgrade|Nanopi-Neo-Plus2-ext4-sysupgrade"
        "-friendlyarm_nanopi-r1s-h5-ext4-sysupgrade|Nanopi-R1-H5-ext4-sysupgrade"
        "-firefly_roc-rk3328-cc-ext4-sysupgrade|Firefly_Roc-RK3328-CC-ext4-sysupgrade"
        
        "-firefly_roc-rk3328-cc-squashfs-sysupgrade|Firefly_Roc-RK3328-CC-squashfs-sysupgrade"
        "-friendlyarm_nanopi-r2c-squashfs-sysupgrade|Nanopi-R2C-squashfs-sysupgrade"
        "-friendlyarm_nanopi-r2c-plus-squashfs-sysupgrade|Nanopi-R2C-Plus-squashfs-sysupgrade"
        "-friendlyarm_nanopi-r2s-squashfs-sysupgrade|Nanopi-R2S-squashfs-sysupgrade"
        "-friendlyarm_nanopi-r2s-plus-squashfs-sysupgrade|Nanopi-R2S-Plus-squashfs-sysupgrade"
        "-friendlyarm_nanopi-r3s-squashfs-sysupgrade|Nanopi-R3S-squashfs-sysupgrade"
        "-friendlyarm_nanopi-r4s-squashfs-sysupgrade|Nanopi-R4S-squashfs-sysupgrade"
        "-friendlyarm_nanopi-r5s-squashfs-sysupgrade|Nanopi-R5S-squashfs-sysupgrade"
        "-friendlyarm_nanopi-r6s-squashfs-sysupgrade|Nanopi-R6S-squashfs-sysupgrade"
        "-friendlyarm_nanopi-neo2-squashfs-sysupgrade|Nanopi-Neo2-squashfs-sysupgrade"
        "-friendlyarm_nanopi-neo-plus2-squashfs-sysupgrade|Nanopi-Neo-Plus2-squashfs-sysupgrade"
        "-friendlyarm_nanopi-r1s-h5-squashfs-sysupgrade|Nanopi-R1S-H5-squashfs-sysupgrade"
         
        # Amlogic ULO
        "-s905x-b860h-|s905x-B860H"
        "-s905x-hg680p-|s905x-HG680P"
        "-s905x2-b860hv5-|s905x2-B860Hv5"
        "-s905x2-hg680-fj-|s905x2-HG680-FJ"
        "-s905x3-|s905x3"
        "-s905x4-|s905x4_AT01-Ax810"
        
        # Amlogic Ophub
        "_s905x_|s905x_HG680P-WIFIOFF"
        "_s905x-b860h_|s905x_B860H-WIFIOFF"
        "_s905d_|s905d_Phicomm-N1"
        "_s905l-mg101_|s905l_Mibox-4"
        "_s905l_|s905l_B860AV2"
        "_s905l2_|s905l2_M301A"
        "_s905l3_|s905l3_HG680-LC"
        "_s905l3b-e900v22e_|s905l3b_MGV2000"
        "_s905lb-q96-mini_|s905lb_Q96-mini"
        "_s905l3a-m401a_|s905l3a_B863AV3"
        "_s905-mxqpro-plus_|s905_MXQ-Pro+"
        "_s922x-gtking_|s922x_GtKing"
        "_s922x_|s922x_GtKing-Pro"
        "_s922x-gtkingpro-h_|s922x_GtKing-Pro-H"
        "_s922x-ugoos-am6_|s922x_UGOOS-AM6-Plus"
        "_s912-nexbox-a1_|s912_Nexbox-A1-A95X"
        "_s912-nexbox-a2_|s912_Nexbox-A95X-A2"
        "_s905l2_|s905l2_MGV_M301A"
        "_s905x2-x96max-2g_|s905x2-x96Max2Gb-A95X-F2"
        "_s905x2_|s905x2_x96Max-4Gb-Tx5-Max"
        "_s905x2-b860h-v5_|s905x2_B860Hv5"
        "_s905x2-hg680-fj_|s905x2_HG680-FJ"
        "_s905x3-x96air_|s905x3-X96Air100M"
        "_s905x3-x96air-gb_|s905x3-x96Air1Gbps"
        "_s905x3-hk1_|s905x3-HK1BOX"
        "_s905x3_|s905x3_X96MAX+_100Mb"
        "_s905x3-x96max_|s905x3_X96MAX+_1Gb"
        "_s905x3-a95xf3-gb_|s905x3_A95xF3-1Gb"
        "_s905x3-a95xf3_|s905x3_A95xF3-100M"
        "_s905x3-x88-pro-x3_|s905x3_X88-Pro-X3"
        "_s905x4-advan_|s905x4_AT01-AX810"
        "_s905w_|s905w_TX3_Mini"
        "_s905w-x96-mini_|s905w-X96-Mini"
        
        # Allwinner Ophub
        "_allwinner_orangepi-3_|OrangePi_3"
        "_allwinner_orangepi-zplus_|OrangePi_ZeroPlus"
        "_allwinner_orangepi-zplus2_|OrangePi_ZeroPlus2"
        "_allwinner_orangepi-zero2_|OrangePi_Zero2"
        "_allwinner_orangepi-zero3_|OrangePi_Zero3"
        
        # Rockchip Ophub
        "_rk3318-box_|rk3318-Box"
        "_renegade-rk3328_|Firefly-RK3328"
        "_h96-max-m2_|rk3528-H96-Max"
        "_panther-x2_|rk3566-Panther-X2"
        "_rock5b_|rk3588-Rock5B"
        "_king3399_|rk3399-King3399"
        
        # friendlyarm Ophub
        "_nanopi-r5s_|Nanopi-r5s"
        "_nanopi-r5c_|Nanopi-r5c"
        
        # x86_64 Official
        "x86-64-generic-ext4-combined-efi|X86_64_Generic_Ext4_Combined_EFI"
        "x86-64-generic-ext4-combined|X86_64_Generic_Ext4_Combined"
        "x86-64-generic-ext4-rootfs|X86_64_Generic_Ext4_Rootfs"
        "x86-64-generic-squashfs-combined-efi|X86_64_Generic_Squashfs_Combined_EFI"
        "x86-64-generic-squashfs-combined|X86_64_Generic_Squashfs_Combined"
        "x86-64-generic-squashfs-rootfs|X86_64_Generic_Squashfs_Rootfs"
        "x86-64-generic-rootfs|X86_64_Generic_Rootfs"
    )

   for pattern in "${search_replace_patterns[@]}"; do
        local search="${pattern%%|*}"
        local replace="${pattern##*|}"

        for file in *"${search}"*.img.gz; do
            if [[ -f "$file" ]]; then
                local kernel=""
                if [[ "$file" =~ k[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9-]+)? ]]; then
                    kernel="${BASH_REMATCH[0]}"
                fi
                local new_name
                if [[ -n "$kernel" ]]; then
                    new_name="XIDZs-${OP_BASE}-${BRANCH}-${replace}-${kernel}-${TUNNEL}-${DATE}.img.gz"
                else
                    new_name="XIDZs-${OP_BASE}-${BRANCH}-${replace}-${TUNNEL}-${DATE}.img.gz"
                fi
                echo -e "${INFO} Renaming: $file → $new_name"
                mv "$file" "$new_name" || {
                    echo -e "${WARN} Failed to rename $file"
                    continue
                }
            fi
        done
        for file in *"${search}"*.tar.gz; do
            if [[ -f "$file" ]]; then
                local new_name
                new_name="XIDZs-${OP_BASE}-${BRANCH}-${replace}-${TUNNEL}-${DATE}.img.gz"
                echo -e "${INFO} Renaming: $file → $new_name"
                mv "$file" "$new_name" || {
                    echo -e "${WARN} Failed to rename $file"
                    continue
                }
            fi
        done
    done

    sync && sleep 3
    echo -e "${INFO} Rename operation completed."
}

rename_firmware
