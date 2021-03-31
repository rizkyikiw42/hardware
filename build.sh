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

pushd hw/quartus
make rbf
make dtb
make preloader

pushd software/spl_bsp

[ ! -d "u-boot-socfpga" ] \
    && git clone --depth=1 --branch=ACDS20.1STD_REL_GSRD_PR https://github.com/altera-opensource/u-boot-socfpga

pushd u-boot-socfpga

./arch/arm/mach-socfpga/qts-filter.sh cyclone5 ../../../ ../ ./board/terasic/de1-soc/qts/

make socfpga_cyclone5_defconfig
make -j5

popd
popd
popd

