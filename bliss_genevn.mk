#
# Copyright (C) 2022 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
TARGET_SUPPORTS_OMX_SERVICE := false
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit from genevn device
$(call inherit-product, device/motorola/genevn/device.mk)

# Inherit some common BlissROM stuff.
$(call inherit-product, vendor/bliss/config/common_full_phone.mk)

PRODUCT_NAME := bliss_genevn
PRODUCT_DEVICE := genevn
PRODUCT_MANUFACTURER := motorola
PRODUCT_BRAND := motorola
PRODUCT_MODEL := moto g stylus 5G - 2023

PRODUCT_GMS_CLIENTID_BASE := android-motorola

PRODUCT_BUILD_PROP_OVERRIDES += \
    DeviceProduct="genevn_g" \
    BuildDesc="genevn_g-user 14 U1TGNS34.42-86-2-38 75e6c-32d474 release-keys MUR1-0.143" \
    BuildFingerprint="motorola/genevn_g/genevn:14/U1TGNS34.42-86-2-38/75e6c-32d474:user/release-keys"

# A-Team signing configuration
$(call inherit-product, vendor/ateam/android.mk)
