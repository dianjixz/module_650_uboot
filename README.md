# MODULE_LLM_UBOOT
Patch for the uboot adapted for the module_llm development board.  
Compilation will automatically download and apply the relevant patches to compile into a uboot project.  


auto compile:
```bash
make ARCH=arm CROSS_COMPILE=aarch64-none-linux-gnu- AX650_emmc_defconfig
make ARCH=arm CROSS_COMPILE=aarch64-none-linux-gnu- -j `nproc`
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


KCFLAGS="-DOPTEE_BOOT -DOPTEE_IMAGE_ADDR="0x134000000" -DOPTEE_RESERVED_SIZE="0x2000000" -DOPTEE_SHMEM_SIZE="0x200000""









