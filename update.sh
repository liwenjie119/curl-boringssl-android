#!/bin/bash
git pull
cd boringssl
git checkout master
git checkout .
git pull
cd ../brotli
git checkout master
git checkout .
git pull
cd ../busybox
git checkout master
git checkout .
git pull
cd ../c-ares
git checkout master
git checkout .
git pull
cd ../curl
git checkout master
git checkout .
git pull
cd ../libexpat
git checkout master
git checkout .
git pull
cd ../libmetalink
git checkout master
git checkout .
git pull
cd ../libpsl
git checkout master
git checkout .
git pull
cd ../libssh2
git checkout master
git checkout .
git pull
cd ../nghttp2
git checkout master
git checkout .
git pull
cd ../openssl
git checkout master
git checkout .
git pull
cd ../zlib
git checkout develop
git checkout .
git pull
cd ..

