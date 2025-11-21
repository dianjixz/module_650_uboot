# SPDX-FileCopyrightText: 2024 M5Stack Technology CO LTD
# SPDX-License-Identifier: MIT

# ============================================================================
# 配置区域 - 根据需求修改此部分
# ============================================================================
THIS_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
# ----------------------------------------------------------------------------
# Uboot 版本配置
# ----------------------------------------------------------------------------
UBOOT_VERSION       := 2020.04
UBOOT_TAR_SHA       := fe732aaf037d9cc3c0909bad8362af366ae964bbdac6913a34081ff4ad565372

# 源码下载 URL（可选其他镜像）
UBOOT_TAR_URL       := https://ftp.denx.de/pub/u-boot/u-boot-$(UBOOT_VERSION).tar.bz2

# ----------------------------------------------------------------------------
# 板级配置
# ----------------------------------------------------------------------------
BOARD_NAME          := m5stack_AX650C
BOARD_ARCH          := arm
BASE_DEFCONFIG      := AX650_emmc_defconfig
TARGET_DEFCONFIG    := $(BOARD_NAME)_emmc_$(BOARD_ARCH)_defconfig

# ----------------------------------------------------------------------------
# 目录配置
# ----------------------------------------------------------------------------
PATCH_DIR           := patches
DTS_DIR             := uboot-dts
CONFIG_DIR          := 


# ----------------------------------------------------------------------------
# 下载目录配置
# ----------------------------------------------------------------------------
# 外部下载目录路径
DOWNLOAD_DIR        := $(THIS_DIR)/../../../dl

# ----------------------------------------------------------------------------
# 交叉编译配置（如需要请取消注释）
# ----------------------------------------------------------------------------
# ARCH              := arm64
# CROSS_COMPILE     := aarch64-none-linux-gnu-
# KERNEL_EXTRA_PARAMS := ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE)

# ============================================================================
# 内部变量 - 通常不需要修改
# ============================================================================

# 确定下载目录

DL_DIR := .
ifneq ($(wildcard $(DOWNLOAD_DIR)),)
	DL_DIR := $(DOWNLOAD_DIR)
endif

# 目录和文件定义
BUILD_DIR           := build
SRC_DIR             := $(BUILD_DIR)/u-boot-$(UBOOT_VERSION)
UBOOT_TAR_NAME      := $(UBOOT_TAR_SHA)-u-boot-$(UBOOT_VERSION).tar.bz2
UBOOT_TAR			:= $(DL_DIR)/.$(UBOOT_TAR_NAME)

# 收集源文件
PATCHES             := $(sort $(wildcard $(PATCH_DIR)/*.patch))
DTSS                := $(wildcard $(DTS_DIR)/*.dts*) $(wildcard $(DTS_DIR)/*.h)
CONFIG_FILES        := $(wildcard $(CONFIG_DIR)/*.config)
SYMLINK_DIRS      	:= 




# 内核编译命令
KERNEL_MAKE := +$(MAKE) -C $(SRC_DIR)  dtb-y=m5stack-ax650.dtb DEVICE_TREE=m5stack-ax650 $(KERNEL_EXTRA_PARAMS)

# ============================================================================
# 主要目标
# ============================================================================
SIGN_EXTS := all install %_defconfig oldconfig %.bin u-boot

define SIGN_RULE
$(1): _build_init
	$(KERNEL_MAKE) $(MAKECMDGOALS)
	[ -f '$(SRC_DIR)/u-boot' ] && cp $(SRC_DIR)/u-boot* . || exit 0
endef

$(foreach ext,$(SIGN_EXTS),$(eval $(call SIGN_RULE,$(ext))))

# ============================================================================
# 构建流程
# ============================================================================

# 构建初始化总入口
_build_init: Patching Extracting

# 构建流程依赖链

Patching: $(BUILD_DIR)/.stamp_patching $(BUILD_DIR)/.stamp_dtsing $(BUILD_DIR)/.stamp_config

Extracting: $(BUILD_DIR)/.stamp_extract

# ============================================================================
# 内部辅助目标（不直接调用）
# ============================================================================

$(BUILD_DIR)/.stamp_config : $(CONFIG_FILES) $(BUILD_DIR)/.stamp_patching
	cat $(SRC_DIR)/configs/$(BASE_DEFCONFIG)	$(CONFIG_FILES) > $(SRC_DIR)/configs/$(TARGET_DEFCONFIG) && touch $@

$(BUILD_DIR)/.stamp_patching : $(PATCHES) $(BUILD_DIR)/.stamp_extract
	for p in $(PATCHES); do patch -p1 -d $(SRC_DIR) < $$p; done && touch $@

$(BUILD_DIR)/.stamp_dtsing : $(DTSS) $(BUILD_DIR)/.stamp_extract
	cp $(DTSS) $(SRC_DIR)/arch/$(BOARD_ARCH)/dts/ && touch $@


$(BUILD_DIR)/.stamp_extract : $(UBOOT_TAR)
	mkdir -p $(BUILD_DIR)
	tar xjf $(UBOOT_TAR) -C $(BUILD_DIR) && { for d in $(SYMLINK_DIRS); do ln -sf $(SRC_DIR)/$$d $$d; done } && touch $@
	 

$(UBOOT_TAR) : README.md
	@if [ ! -f "$(UBOOT_TAR)" ]; then \
		wget --passive-ftp -nd -t 3 -O '$(UBOOT_TAR)' '$(UBOOT_TAR_URL)' || rm -f '$(UBOOT_TAR)'; \
	else \
		touch '$(UBOOT_TAR)'; \
	fi
	







AXERA_TOOLS_PATH := $(THIS_DIR)/axerabin/tools/bin
BINARIES_DIR := $(SRC_DIR)
OUT_BINARIES_DIR := $(SRC_DIR)/..
ifneq ($(wildcard $(AXERA_TOOLS_PATH)/ax650n_BuildEnv.mk),)
include $(AXERA_TOOLS_PATH)/ax650n_BuildEnv.mk

Packaxera: 
	openssl aes-256-ecb -e -in $(BINARIES_DIR)/u-boot.bin -out $(OUT_BINARIES_DIR)/u-boot_enc.bin -K 00000000000000000000000000000000 -nosalt -p
	python3 $(AXERA_TOOLS_SIGN_SCRIPT_650_BK) -i $(BINARIES_DIR)/u-boot.bin \
		-o $(OUT_BINARIES_DIR)/u-boot_signed.bin -ob $(OUT_BINARIES_DIR)/uboot_bk.bin -pub $(AXERA_TOOLS_PUB_KEY) -prv $(AXERA_TOOLS_PRIV_KEY) \
		-fw $(AXERA_TOOLS_PATH)/imgsign/eip.bin  $(AXERA_TOOLS_SIGN_PARAMS_650_UBOOT)

	python3 $(AXERA_TOOLS_SIGN_SCRIPT_650_BK) -i $(OUT_BINARIES_DIR)/u-boot_enc.bin \
		-o $(OUT_BINARIES_DIR)/u-boot_enc_signed.bin -ob $(OUT_BINARIES_DIR)/uboot_enc_bk.bin -pub $(AXERA_TOOLS_PUB_KEY) -prv $(AXERA_TOOLS_PRIV_KEY) \
		-fw $(AXERA_TOOLS_PATH)/imgsign/eip.bin  $(AXERA_TOOLS_SIGN_PARAMS_650_UBOOT)

	python3 $(AXERA_TOOLS_SIGN_SCRIPT_650_FDL) -i $(BINARIES_DIR)/u-boot.bin \
		-o $(OUT_BINARIES_DIR)/fdl2_signed.bin -pub $(AXERA_TOOLS_PUB_KEY) -prv $(AXERA_TOOLS_PRIV_KEY) \
		-fw $(AXERA_TOOLS_PATH)/imgsign/eip.bin  $(AXERA_TOOLS_SIGN_PARAMS_650_UBOOT)
else
Packaxera: 
        @echo "Axera signing tools not found. Skipping signing step."
endif

linux-distclean:
	@$(KERNEL_MAKE) distclean

distclean:
	@rm -f build -rf
	@rm -f ._build.lock
	@rm -f u-boot*



















