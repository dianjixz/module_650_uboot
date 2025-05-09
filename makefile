# SPDX-FileCopyrightText: 2024 M5Stack Technology CO LTD
#
# SPDX-License-Identifier: MIT

PATCH_DIR := patches
SRC_DIR := build/u-boot-2020.04
PATCHES := $(wildcard patches/*.patch)
DTSS := $(wildcard uboot-dts/*.dts*)
CONFIG_FILES := $(wildcard *.config)
UBOOT_TAR_SHA := fe732aaf037d9cc3c0909bad8362af366ae964bbdac6913a34081ff4ad565372
# AX630C_KERNEL_PARAM := ARCH=arm CROSS_COMPILE=aarch64-none-linux-gnu- 
# KERNEL_MAKE := cd $(SRC_DIR) ; $(MAKE) $(AX630C_KERNEL_PARAM)

KERNEL_MAKE := cd $(SRC_DIR) ; $(MAKE) 
%:
	@if [ "$(MAKECMDGOALS)" != "build_init" ] ; then \
		$(MAKE) build_init ; \
		$(KERNEL_MAKE) dtb-y=m5stack-ax650.dtb DEVICE_TREE=m5stack-ax650 $(MAKECMDGOALS) ; \
		if [ -f "u-boot" ] ; then cp u-boot* ../.. ; fi ; \
	fi

build_init:Configuring

Extracting:
	@$(MAKE) build/check_build.tmp
	@$(MAKE) build/check_dts.tmp

Patching:Extracting 
	@$(MAKE) build/check_patch.tmp

Configuring:Patching 
	@$(MAKE) build/check_config.tmp  

build/check_build.tmp:$(PATCHES)
	[ -d 'build' ] || mkdir build
	@if [ -f '.stamp_extracted' ] ; then \
		[ -f '../../../dl/u-boot-2020.04.tar.bz2' ] || wget --passive-ftp -nd -t 3 -O '../../../dl/u-boot-2020.04.tar.bz2' 'https://ftp.denx.de/pub/u-boot/u-boot-2020.04.tar.bz2' ; \
		calculated_hash=$$(sha256sum ../../../dl/u-boot-2020.04.tar.bz2 | awk '{ print $$1 }'); \
		if [ "$$calculated_hash" != "$(UBOOT_TAR_SHA)" ]; then \
			rm ../../../dl/u-boot-2020.04.tar.bz2 ; \
			exit 1; \
		fi ; \
		[ -d 'build/u-boot-2020.04' ] || tar xjf ../../../dl/u-boot-2020.04.tar.bz2 -C build/ ; \
	else \
		[ -f '.u-boot-2020.04.tar.bz2' ] || wget --passive-ftp -nd -t 3 -O '.u-boot-2020.04.tar.bz2' 'https://ftp.denx.de/pub/u-boot/u-boot-2020.04.tar.bz2' ; \
		calculated_hash=$$(sha256sum .u-boot-2020.04.tar.bz2 | awk '{ print $$1 }') ; \
		if [ "$$calculated_hash" != "$(UBOOT_TAR_SHA)" ]; then \
			rm .u-boot-2020.04.tar.bz2 ; \
			exit 1; \
		fi ; \
		[ -d 'build/u-boot-2020.04' ] || tar xjf .u-boot-2020.04.tar.bz2 -C build/ ; \
	fi
	@touch build/check_build.tmp

build/check_dts.tmp:$(DTSS)
	@cp uboot-dts/* $(SRC_DIR)/arch/arm/dts/
	@touch build/check_dts.tmp

build/check_patch.tmp:$(PATCHES)
	@[ -d 'build/u-boot-2020.04/arch/arm/mach-axera' ] || {\
		for patch in $^; do \
			echo "Applying $$patch..."; \
			patch -p1 -d build <$$patch || { echo "Failed to apply $$patch"; exit 1; } \
		done ; \
	}
	@touch build/check_patch.tmp

build/check_config.tmp:$(CONFIG_FILES)
	@touch build/check_config.tmp

distclean:
	@rm -f build -rf
	@rm -f u-boot u-boot.* u-boot*.bin

uboot-distclean:
	@$(KERNEL_MAKE) distclean
	@rm -f build/check_config.tmp 

