# MODULE_650_UBOOT
Patch for the uboot adapted for the module_llm development board.  
Compilation will automatically download and apply the relevant patches to compile into a uboot project.  


auto compile:
```bash
sudo apt install flex bison libssl-dev libelf-dev
source /opt/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bash.bashrc
make distclean
make ARCH=arm CROSS_COMPILE=aarch64-linux-gnu- AX650_emmc_defconfig
make ARCH=arm CROSS_COMPILE=aarch64-linux-gnu- -j `nproc`
axp_pack_bin u-boot.bin u-boot_signed.bin
```

just Extract:
```bash
make Extracting
```

just Patch:
```bash
make Patching
```

just Configur:
```bash
make Configuring
```











