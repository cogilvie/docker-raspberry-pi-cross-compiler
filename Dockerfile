FROM debian:buster

# Set up host tools
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y apt-utils \
 && DEBIAN_FRONTEND=noninteractive dpkg-reconfigure apt-utils \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        automake \
        cmake \
        curl \
        fakeroot \
        g++ \
        git \
        make \
        runit \
        sudo \
        pkg-config \
        xz-utils \
        wget \
        python \
        build-essential \
        qemu \
        qemu-user-static \
        binfmt-support

# Here is where we hardcode the toolchain decision.
ENV HOST=arm-linux-gnueabihf \
    TOOLCHAIN=gcc-linaro-arm-linux-gnueabihf-raspbian-x64 \
    RPXC_ROOT=/rpxc

WORKDIR $RPXC_ROOT
RUN curl -L https://github.com/raspberrypi/tools/tarball/master \
  | tar --wildcards --strip-components 3 -xzf - "*/arm-bcm2708/$TOOLCHAIN/" "*/${HOST}-pkg-config"

ENV ARCH=arm \
    CROSS_COMPILE=$RPXC_ROOT/bin/$HOST- \
    PATH=$RPXC_ROOT/bin:$PATH \
    SYSROOT=$RPXC_ROOT/sysroot \
    WORKSPACE=/workspace


WORKDIR $SYSROOT

#download and unpack the RPI disk image
RUN wget https://downloads.raspberrypi.org/raspbian_lite/archive/2019-09-30-15:24/root.tar.xz 
RUN tar -xJf root.tar.xz 

# chroot into the rpi image and use qemu to update and install extra packages
RUN chroot $SYSROOT /bin/sh -c '\
        uname -a \
        && echo "deb http://archive.raspbian.org/raspbian buster main contrib non-free rpi firmware\ndeb-src http://archive.raspbian.org/raspbian/ buster main contrib non-free rpi firmware"  >> /etc/apt/sources.list \
        && apt-get update \
        && DEBIAN_FRONTEND=noninteractive apt-get install -y apt-utils \
        && DEBIAN_FRONTEND=noninteractive dpkg-reconfigure apt-utils \
        && DEBIAN_FRONTEND=noninteractive apt-get -y update \
        && DEBIAN_FRONTEND=noninteractive apt-get -y upgrade \
        && DEBIAN_FRONTEND=noninteractive apt-get -y build-dep qt4-x11 \
        && DEBIAN_FRONTEND=noninteractive apt-get -y build-dep libqt5gui5 \
        && DEBIAN_FRONTEND=noninteractive apt-get -y install libudev-dev libinput-dev libts-dev libxcb-xinerama0-dev libxcb-xinerama0'


WORKDIR $RPXC_ROOT

#fix symlincs for cross compiling
RUN wget https://raw.githubusercontent.com/Kukkimonsuta/rpi-buildqt/master/scripts/utils/sysroot-relativelinks.py \
    && chmod +x sysroot-relativelinks.py \
    && ./sysroot-relativelinks.py sysroot

WORKDIR $WORKSPACE

# Get Qt
RUN git clone https://code.qt.io/qt/qt5.git qtsource \
    && cd qtsource \
    && git checkout 5.12.6 \
    && perl init-repository --module-subset=default,-qtwebkit,-qtwebkit-examples,-qtwebengine,-qt3d,-qtandroidextras,-qtwinextras,-qtmacextras,-qtlocation,-qtscript \
    && cd -

#Apply patch to qxcbeglwindow fix for QTBUG-75328
COPY patches .
RUN cd qtsource/qtbase && git apply $WORKSPACE/qxcbeglwindow.diff && cd -

# Configure Qt
RUN cd qtsource \
    && ./configure -device linux-rasp-pi3-g++ \
        -device-option CROSS_COMPILE=$CROSS_COMPILE \
        -sysroot $SYSROOT -prefix /opt/qt5 -extprefix /opt/qt5 \
        -release -opengl es2 -opensource -static -no-use-gold-linker -confirm-license \
        -nomake examples -nomake tests \
        -skip location -skip script -v \
    && cd -

# Build Qt
RUN cd qtsource \
    && make -j12 \
    && make install \
    && cd -

