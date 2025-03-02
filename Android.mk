LOCAL_PATH := $(call my-dir)

ifeq ($(TARGET_DEVICE),msi)
include $(call all-subdir-makefiles,$(LOCAL_PATH))
endif
