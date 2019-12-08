#!/bin/bash

# Set up Android NDK
NDK=r20b
echogreen "Fetching Android NDK $NDK"
[ -f "android-ndk-$NDK-linux-x86_64.zip" ] || wget https://dl.google.com/android/repository/android-ndk-$NDK-linux-x86_64.zip
[ -d "android-ndk-$NDK" ] || unzip -qo android-ndk-$NDK-linux-x86_64.zip

# Get latest certs
[ -f "cacert.pm" ] || curl --remote-name --time-cond cacert.pem https://curl.haxx.se/ca/cacert.pem

export ANDROID_NDK_HOME=`pwd`/android-ndk-$NDK
export HOST_TAG=linux-x86_64
export MIN_SDK_VERSION=21
if [ -f /proc/cpuinfo ]; then
  export JOBS=$(grep flags /proc/cpuinfo | wc -l)
elif [ ! -z $(which sysctl) ]; then
  export JOBS=$(sysctl -n hw.ncpu)
else
  export JOBS=2
fi

export CFLAGS="-Os -ffunction-sections -fdata-sections -fno-unwind-tables -fno-asynchronous-unwind-tables"
export LDFLAGS="-Wl,-s -Wl,-Bsymbolic -Wl,--gc-sections"

chmod +x build-zlib.sh build-openssl.sh build-curl.sh

./build-zlib.sh
./build-openssl.sh
./build-curl.sh
