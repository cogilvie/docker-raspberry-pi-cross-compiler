# Raspberry Pi 3 Cross-Compiler in a Docker Container wit Qt

An easy-to-use  all-in-one cross compiler for the Raspberry Pi 3.

This project is available as [cogilvie/docker-raspberry-pi-cross-compiler](https://github.com/cogilvie/docker-raspberry-pi-cross-compiler) on [GitHub](https://github.com).

Please raise any issues on the [GitHub issue tracker](https://github.com/cogilvie/docker-raspberry-pi-cross-compiler/issues).

## Contents

* [Features](#features)
* [Installation](#installation)
* [Usage](#usage)
* [Custom Images](#custom-images)


## Features

* The [gcc-linaro-arm-linux-gnueabihf-raspbian-x64 toolchain](https://github.com/raspberrypi/tools/tree/master/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64) from [raspberrypi/tools](https://github.com/raspberrypi/tools)
* Raspbian sysroot from [raspberrypi.org](https://downloads.raspberrypi.org/raspbian_lite/archive/2019-09-30-15:24/root.tar.xz ) :new:


## Installation

build the image from the root dir this is required to correctly add the patches to the container

eg.
```
docker build . -t cogilvie/docker-raspberry-pi-cross-compiler:latest
```

## Usage

The image works with [vscode Remote development](https://code.visualstudio.com/docs/remote/containers)

## Custom Images

### Create a Dockerfile

To add new features to the sysroot

```Dockerfile
FROM cogilvie/raspberry-pi-cross-compiler


RUN chroot $SYSROOT /bin/sh -c '\
        && DEBIAN_FRONTEND=noninteractive apt-get -y install <your libs>'

#fix symlincs for cross compiling
RUN $RPXC_ROOT/sysroot-relativelinks.py $SYSROOT

```


