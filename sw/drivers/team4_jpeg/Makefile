obj-m += team4_jpeg.o

PWD := $(shell pwd)
KERNEL_SOURCE := ../../linux-socfpga 

all:
	make ARCH=arm CROSS_COMPILE=arm-eabi- -C $(KERNEL_SOURCE) M=$(PWD) modules

.PHONY: clean
clean:
	make -C $(KERNEL_SOURCE) M=$(PWD) clean
