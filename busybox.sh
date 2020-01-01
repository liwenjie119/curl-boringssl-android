#!/bin/bash
cp -f .config busybox/.config
wget -b -c http://releases.linaro.org/components/toolchain/binaries/7.5-2019.12/aarch64-linux-gnu/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu.tar.xz
tar -xJf gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu.tar.xz
export CROSS_COMPILE=$PWD/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-
cd busybox
git checkout master
git pull
make -j8 ARCH=arm64  &&make -j8 ARCH=arm64  install
cd ..
