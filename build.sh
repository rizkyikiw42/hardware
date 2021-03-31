#!/usr/bin/env bash

export SOCEDS_DEST_ROOT=/opt/intelFPGA/20.1/embedded
export QUARTUS_ROOTDIR=/opt/intelFPGA_lite/20.1/quartus
. /opt/intelFPGA_lite/20.1/quartus/adm/qenv.sh
. /opt/intelFPGA/20.1/embedded/env.sh
export PATH=/opt/intelFPGA/20.1/embedded/host_tools/linaro/gcc/bin:$PATH

set -e

cd /src/

export ARCH=arm
export CROSS_COMPILE=arm-eabi-

# pushd hw/quartus
# make rbf
# make dtb
# make preloader

# pushd software/spl_bsp

# [ ! -d "u-boot-socfpga" ] \
#     && git clone --depth=1 --branch=ACDS20.1STD_REL_GSRD_PR https://github.com/altera-opensource/u-boot-socfpga

# pushd u-boot-socfpga

# ./arch/arm/mach-socfpga/qts-filter.sh cyclone5 ../../../ ../ ./board/terasic/de1-soc/qts/

# make socfpga_cyclone5_defconfig
# make -j5

# popd
# popd
# popd

pushd sw/sdcard
../../hw/quartus/software/spl_bsp/u-boot-socfpga/tools/mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n "Cyclone V script" -d u-boot.txt u-boot.scr
popd

pushd sw
[ ! -d "linux-socfpga" ] \
    && git clone --depth=1 --branch=ACDS20.1STD_REL_GSRD_PR https://github.com/altera-opensource/linux-socfpga

pushd linux-socfpga

make socfpga_defconfig
make -j 5 zImage modules
make modules_install INSTALL_MOD_PATH=modules_install
rm -rf modules_install/lib/modules/*/build
rm -rf modules_install/lib/modules/*/source

popd
popd
