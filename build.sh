#!/bin/bash

NDK=r22-beta1
export ANDROID_NDK_HOME=$PWD/android-ndk-$NDK
export HOST_TAG=linux-x86_64
export MIN_SDK_VERSION=29
export STATIC=true
export ARCH="arm64"

if [ -f /proc/cpuinfo ]; then
  export JOBS=$(grep flags /proc/cpuinfo | wc -l)
elif [ ! -z $(which sysctl) ]; then
  export JOBS=$(sysctl -n hw.ncpu)
else
  export JOBS=2
fi

# Set up Android NDK
[ -f "android-ndk-$NDK-$HOST_TAG.zip" ] || wget -q https://dl.google.com/android/repository/android-ndk-$NDK-$HOST_TAG.zip
[ -d "android-ndk-$NDK" ] || unzip -qo android-ndk-$NDK-$HOST_TAG.zip
export TOOLCHAIN=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/$HOST_TAG
export PATH=$TOOLCHAIN/bin:$PATH

export DIR=$PWD
$STATIC && CFLAGS="--static " LDFLAGS="--static "
export CFLAGS="$CFLAGS-Os -ffunction-sections -fdata-sections -fno-unwind-tables -fno-asynchronous-unwind-tables"
export LDFLAGS="$LDFLAGS-Wl,-s -Wl,-Bsymbolic -Wl,--gc-sections"
export CFLAGSORIG="$CFLAGS"
export LDFLAGSORIG="$LDFLAGS"

chmod +x build-modules.sh
./build-modules.sh
