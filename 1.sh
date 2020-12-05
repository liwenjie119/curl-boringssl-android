#!/bin/bash
git clone https://github.com/mirror/busybox/ 1
cp -f .config 1/.config
cd 1
[ -f "gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu.tar.xz" ] || wget -q http://releases.linaro.org/components/toolchain/binaries/7.5-2019.12/aarch64-linux-gnu/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu.tar.xz
[ -d "gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu" ] || tar -xJf gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu.tar.xz
#wget -q http://releases.linaro.org/components/toolchain/binaries/7.5-2019.12/aarch64-linux-gnu/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu.tar.xz
tar -xJf gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu.tar.xz
export CROSS_COMPILE=$PWD/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-
#自动保存并退出菜单

(echo -e \'\\0x65\'; echo -e \'\\0x79\') | make ARCH=arm64 menuconfig
cp -f .config ../.config 
cd ..
rm -rf 1
