#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017-2021 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

DEVICE=vayu
VENDOR=xiaomi

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

SECTION=
KANG=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        -n | --no-cleanup )
                CLEAN_VENDOR=false
                ;;
        -k | --kang )
                KANG="--kang"
                ;;
        -s | --section )
                SECTION="${2}"; shift
                CLEAN_VENDOR=false
                ;;
        * )
                SRC="${1}"
                ;;
    esac
    shift
done

# Get the host OS
HOST="$(uname | tr '[:upper:]' '[:lower:]')"
PATCHELF_TOOL="${ANDROID_ROOT}/prebuilts/tools-extras/${HOST}-x86/bin/patchelf"

# Check if prebuilt patchelf exists
if [ -f $PATCHELF_TOOL ]; then
    echo "Using prebuilt patchelf at $PATCHELF_TOOL"
else
    # If prebuilt patchelf does not exist, use patchelf from PATH
    PATCHELF_TOOL="patchelf"
fi

# Do not continue if patchelf is not installed
if [[ $(which patchelf) == "" ]] && [[ $PATCHELF_TOOL == "patchelf" ]] && [[ $FORCE != "true" ]]; then
    echo "The script will not be able to do blob patching as patchelf is not installed."
    echo "Run the script with the argument -f or --force to bypass this check"
    exit 1
fi

if [ -z "${SRC}" ]; then
    SRC="adb"
fi

function blob_fixup() {
    case "${1}" in
        vendor/etc/qdcm_calib_data_xiaomi_36_02_0a_video_mode_dsc_dsi_panel.xml | vendor/etc/qdcm_calib_data_xiaomi_42_02_0b_video_mode_dsc_dsi_panel.xml)
            sed -i "s/dcip3/srgb/" "${2}"
            ;;
        vendor/lib64/camera/components/com.qti.node.watermark.so)
            $PATCHELF_TOOL --add-needed "libpiex_shim.so" "${2}"
            ;;
        vendor/lib/libstagefright_soft_ddpdec.so | vendor/lib/libstagefright_soft_ac4dec.so | \
        vendor/lib/libstagefrightdolby.so | vendor/lib64/libstagefright_soft_ddpdec.so | \
        vendor/lib64/libdlbdsservice.so | vendor/lib64/libstagefright_soft_ac4dec.so | vendor/lib64/libstagefrightdolby.so)
            "${PATCHELF}" --replace-needed "libstagefright_foundation.so" "libstagefright_foundation-v33.so" "${2}"
            ;;
        vendor/etc/dolby/dax-default.xml)
            sed -i "/volume-leveler-enable/ s/true/false/g" "${2}"
            ;;
        vendor/etc/seccomp_policy/vendor.qti.hardware.dsp.policy)
            echo 'madvise: 1' >> ${2}
            ;;
    esac
}
# Initialize the helper
setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" true "${CLEAN_VENDOR}"

extract "${MY_DIR}/proprietary-files.txt" "${SRC}" \
        "${KANG}" --section "${SECTION}"

"${MY_DIR}/setup-makefiles.sh"
