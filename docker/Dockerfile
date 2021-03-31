# The build image (contains Quartus (Cyclone V), SoC EDS, and tools
# for building the Linux kernel and Yocto distribution.

FROM ubuntu:18.04

RUN \
        apt-get update && apt-get -y install expect locales wget libtcmalloc-minimal4 libglib2.0-0 && \
        echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
        locale-gen en_US.UTF-8 && \
        /usr/sbin/update-locale LANG=en_US.UTF-8

WORKDIR /root

RUN \
        wget https://download.altera.com/akdlm/software/acdsinst/20.1std.1/720/ib_installers/QuartusLiteSetup-20.1.1.720-linux.run && \
        wget https://download.altera.com/akdlm/software/acdsinst/20.1std.1/720/ib_installers/cyclonev-20.1.1.720.qdz && \
        chmod +x QuartusLiteSetup-20.1.1.720-linux.run && \
        ./QuartusLiteSetup-20.1.1.720-linux.run --mode unattended --installdir /opt/intelFPGA_lite/20.1 --accept_eula 1 && \
        rm -rf QuartusLiteSetup-20.1.1.720-linux.run cyclonev-20.1.1.720.qdz /opt/intelFPGA_lite/20.1/nios2eds

RUN \
        wget https://download.altera.com/akdlm/software/acdsinst/20.1std/711/ib_installers/SoCEDSSetup-20.1.0.711-linux.run && \
        chmod +x SoCEDSSetup-20.1.0.711-linux.run && \
        ./SoCEDSSetup-20.1.0.711-linux.run --mode unattended --installdir /opt/intelFPGA/20.1 --accept_eula 1 && \
        rm SoCEDSSetup-20.1.0.711-linux.run

RUN \
        apt-get -y install xz-utils

RUN \
        wget http://releases.linaro.org/components/toolchain/binaries/7.5-2019.12/arm-eabi/gcc-linaro-7.5.0-2019.12-i686_arm-eabi.tar.xz && \
        tar xvf gcc-linaro-7.5.0-2019.12-i686_arm-eabi.tar.xz -C . && \
        mv gcc-linaro-7.5.0-2019.12-i686_arm-eabi /opt/intelFPGA/20.1/embedded/host_tools/linaro/gcc && \
        rm gcc-linaro-7.5.0-2019.12-i686_arm-eabi.tar.xz

RUN \
        apt-get -y install software-properties-common

RUN \
        apt-get -y install sed wget cvs subversion \
        git-core coreutils unzip texi2html texinfo \
        docbook-utils gawk make gcc \
        build-essential g++ chrpath \
        mercurial autoconf automake groff libtool \
        kmod cpio parted udev dosfstools \
        bison flex && \
        ln -sf bash /bin/sh

RUN \
        dpkg --add-architecture i386 && \
        apt-get update && \
        apt-get install -y libc6:i386 libncurses5:i386 libstdc++6:i386 zlib1g:i386 bc
