# Build

First, build the docker container containing the build tools.  This
will take a while, as it downloads Quartus, SoC EDS, and cross
compilation tools.  You will need more than 15 GiB free space.

```
cd docker
docker build . -t quartus-cyclonev-soceds
```

Then, start the build proper.  This will take a while, depending on
the steps that have completed/are not yet complete:

- Compile the hardware (~10 minutes)
- Compile uboot (~5 minutes)
- Compile the kernel (~10 minutes)
- Download the Ubuntu rootfs
- Build the SD card image

This needs to run in a privileged container to use the loopback device
to create the SD card image.

Run this from the root of the repository:

```
docker run -it --privileged -v $PWD:/src -w /src quartus-cyclonev-soceds ./build.sh
```

The resulting SD card will be in `sw/sdcard.img`.`
