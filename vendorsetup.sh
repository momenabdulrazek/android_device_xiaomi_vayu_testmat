find device/qcom/sepolicy_vndr -type f -exec sed -i '/\/devices\/platform\/soc\/a84000\.i2c\/i2c-2\/2-0028\/wakeup/d' {} +

# Gcam
rm -rf vendor/mgc
git clone https://bitbucket.org/vendor-mgc/vendor_mgc.git vendor/mgc

# Dolby
rm -rf vendor/dolby
git clone https://gitlab.com/dogpoopy/vendor_dolby.git vendor/dolby

