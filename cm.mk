# Inherit some common CM stuff.
$(call inherit-product, vendor/cm/config/common_full_tablet_wifionly.mk)

# Boot animation
TARGET_SCREEN_WIDTH := 1200
TARGET_SCREEN_HEIGHT := 800

# Release name
PRODUCT_RELEASE_NAME := LG G Pad 7.0
PRODUCT_NAME := cm_v400

$(call inherit-product, device/lge/v400/full_v400.mk)
