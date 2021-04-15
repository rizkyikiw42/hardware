# Tests

To run the hardware tests, you need Modelsim (the testbenches proper
are in `tb/`), and Julia to create the test data (in the reference
implementation directory `ref/`).

To run the driver and software tests, you need the docker container as
described below:

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
docker run -it --privileged --net=host -v $PWD:/src -w /src quartus-cyclonev-soceds ./build.sh
```

The resulting SD card will be in `sw/sdcard.img`.`

# References

- Terasic, for the GHRD template (`soc_system_top.sv`).
- Columbia University's CSEE 4840 website for information on how to
  incorporate linux and our hardware.
- "Pipelined fast 2D DCT architecture for JPEG image compression" by
  Agostini et. al for details on implementing the DCT step of our JPEG
  encoder.
