# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit some common Lineage stuff.
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

# Inherit from genevn device
$(call inherit-product, device/motorola/genevn/device.mk)

PRODUCT_DEVICE := genevn
PRODUCT_NAME := lineage_genevn
PRODUCT_BRAND := motorola
PRODUCT_MODEL := Moto G Stylus 5G (2023)
PRODUCT_MANUFACTURER := motorola

PRODUCT_GMS_CLIENTID_BASE := android-motorola

PRODUCT_BUILD_PROP_OVERRIDES += \
    PRIVATE_BUILD_DESC="genevn_g-user 14 U1TGNS34M.42-86-9 12ff0 release-keys"

BUILD_FINGERPRINT := motorola/genevn_g/genevn:14/U1TGNS34M.42-86-9/12ff0:user/release-keys
