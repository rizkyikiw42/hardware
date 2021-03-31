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

./arch/arm/mach-socfpga/qts-filter.sh cyclone5 ../../../ ../ ./board/altera/cyclone5-socdk/qts/

make socfpga_cyclone5_defconfig
make -j5

popd
popd
popd

pushd sw/boot
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

if [ ! -d "rootfs" ]
then
    wget https://rcn-ee.com/rootfs/eewiki/minfs/ubuntu-20.04-minimal-armhf-2020-05-10.tar.xz
    mkdir rootfs
    tar xvf ubuntu-20.04-minimal-armhf-2020-05-10.tar.xz
    tar xf ubuntu-20.04-minimal-armhf-2020-05-10/armhf-rootfs-ubuntu-focal.tar -C rootfs
fi

cp -f ../hw/quartus/software/spl_bsp/u-boot-socfpga/u-boot-with-spl.sfp .
cp -f ../hw/quartus/output_files/soc_system.rbf boot
cp -f ../hw/quartus/soc_system.dtb boot/socfpga_cyclone5_socdk.dtb
cp -f linux-socfpga/arch/arm/boot/zImage boot

python3 make_sdimage_p3.py -f \
  -P u-boot-with-spl.sfp,num=3,format=raw,size=10M,type=A2 \
  -P rootfs/*,num=2,format=ext2,size=1500M \
  -P boot/*,num=1,format=fat32,size=500M -s 2G \
  -n sdcard.img

popd
