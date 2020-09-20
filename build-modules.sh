#!/bin/bash

# Setting up from source is stupid with these
for i in libunistring-latest libiconv-1.16 libidn2-latest gettext-0.20.1; do
  j="$(echo $i | sed "s/-.*//")"
  [ -f $j.tar.gz ] || { [ "$j" == "libidn2" ] && wget -q -O $j.tar.gz http://mirrors.kernel.org/gnu/libidn/$i.tar.gz || wget -q -O $j.tar.gz http://mirrors.kernel.org/gnu/$j/$i.tar.gz; }
  [ -d $j ] || { tar -xf $j.tar.gz; mv -f $j-* $j; }
done

$STATIC && MODULES="zlib boringssl brotli c-ares nghttp2 curl" || MODULES="zlib boringssl openssl libssh2 libiconv gettext libiconv libunistring libidn2 libpsl brotli libexpat libmetalink c-ares nghttp2 curl"
for BIN in $MODULES; do

  cd $BIN || { echo "$BIN doesn't exist!"; exit 1; }
  case $BIN in
    "libunistring"|"libiconv"|"libidn2"|"gettext") ;;
    *) git clean -dfx; git reset --hard;;
  esac

  for i in $ARCH; do
    export CFLAGS="$CFLAGSORIG" LDFLAGS="$LDFLAGSORIG"
    unset FLAGS

    case $i in
      "arm64"|"aarch64") export TARGET_HOST=aarch64-linux-android; LARCH=arm64-v8a; OSARCH=android-arm64;;
      "arm"|"armeabi"|"armeabi_v7a") export TARGET_HOST=armv7a-linux-androideabi; LARCH=armeabi-v7a; OSARCH=android-arm;;
      "x86"|"i686") export TARGET_HOST=i686-linux-android; LARCH=x86; OSARCH=android-x86;;
      "x64"|"x86_64") export TARGET_HOST=x86_64-linux-android; LARCH=x86_64; OSARCH=android-x86_64;;
      *) echo "Invalid ARCH: $i!"; exit 1;;
    esac

    [ "$LARCH" == "armeabi-v7a" ] && export TARGET_HOST=arm-linux-androideabi
    export AR=$TOOLCHAIN/bin/$TARGET_HOST-ar
    export AS=$TOOLCHAIN/bin/$TARGET_HOST-as
    export LD=$TOOLCHAIN/bin/$TARGET_HOST-ld
    export RANLIB=$TOOLCHAIN/bin/$TARGET_HOST-ranlib
    export STRIP=$TOOLCHAIN/bin/$TARGET_HOST-strip
    [ "$LARCH" == "armeabi-v7a" ] && export TARGET_HOST=armv7a-linux-androideabi
    export CC=$TOOLCHAIN/bin/$TARGET_HOST$MIN_SDK_VERSION-clang
    export CXX=$TOOLCHAIN/bin/$TARGET_HOST$MIN_SDK_VERSION-clang++
    export GCC=$TOOLCHAIN/bin/$TARGET_HOST-gcc
    export GXX=$TOOLCHAIN/bin/$TARGET_HOST-g++
    ln -sf $CC $GCC
    ln -sf $CXX $GXX

    export PREFIX=$DIR/build/$BIN/$LARCH
    export ZLIB_DIR=$DIR/build/zlib/$LARCH
    export SSL_DIR=$DIR/build/openssl/$LARCH
    export BSSL_DIR=$DIR/build/boringssl/$LARCH
    export LSSH2_DIR=$DIR/build/libssh2/$LARCH
    export LUNI_DIR=$DIR/build/libunistring/$LARCH
    export LICO_DIR=$DIR/build/libiconv/$LARCH
    export GT_DIR=$DIR/build/gettext/$LARCH
    export LIDN_DIR=$DIR/build/libidn2/$LARCH
    export LPSL_DIR=$DIR/build/libpsl/$LARCH 
    export BROT_DIR=$DIR/build/brotli/$LARCH
    export LEXP_DIR=$DIR/build/libexpat/$LARCH
    export LMET_DIR=$DIR/build/libmetalink/$LARCH
    export LCA_DIR=$DIR/build/c-ares/$LARCH
    export NGH2_DIR=$DIR/build/nghttp2/$LARCH

    case $BIN in
      "zlib")
        ./configure --prefix=$PREFIX
                    ;;
      "openssl") 
        if $STATIC; then
          sed -i "/#if \!defined(_WIN32)/,/#endif/d" fuzz/client.c
          sed -i "/#if \!defined(_WIN32)/,/#endif/d" fuzz/server.c
        fi
        ./Configure $OSARCH no-shared zlib \
                    -D__ANDROID_API__=$MIN_SDK_VERSION \
                    --prefix=$PREFIX \
                    --with-zlib-include=$ZLIB_DIR/include \
                    --with-zlib-lib=$ZLIB_DIR/lib
                    ;;
      "boringssl") $STATIC && FLAGS="-DCMAKE_EXE_LINKER_FLAGS='-static' "
        mkdir -p build/$LARCH
        cd build/$LARCH/
        cmake -DANDROID_ABI=$LARCH \
              -DCMAKE_TOOLCHAIN_FILE=${ANDROID_NDK_HOME}/build/cmake/android.toolchain.cmake \
              -DANDROID_NATIVE_API_LEVEL=$MIN_SDK_VERSION \
              -DCMAKE_BUILD_TYPE=Release \
              $FLAGS-GNinja $PWD/../..
              ;;
      "libssh2")
        ./buildconf
        ./configure --host=$TARGET_HOST \
                    --target=$TARGET_HOST \
                    --prefix=$PREFIX \
                    --enable-hidden-symbols \
                    --disable-examples-build \
                    --with-crypto=openssl \
                    --with-libssl-prefix=$SSL_DIR \
                    --with-libz \
                    --with-libz-prefix=$ZLIB_DIR
                    ;;
      "libiconv")
        if [ -d "$GT_DIR" ]; then
          ./configure --host=$TARGET_HOST \
                      --target=$TARGET_HOST \
                      --prefix=$PREFIX \
                      --disable-shared \
                      CFLAGS="$CFLAGS -I$GT_DIR/include" \
                      LDFLAGS="$LDFLAGS -L$GT_DIR/lib"
        else
          ./configure --host=$TARGET_HOST \
                      --target=$TARGET_HOST \
                      --prefix=$PREFIX \
                      --disable-shared
        fi
        ;;
      "gettext")
        ./configure --host=$TARGET_HOST \
                    --target=$TARGET_HOST \
                    --prefix=$PREFIX \
                    --without-libintl \
                    --with-libiconv-prefix=$LICO_DIR \
                    --disable-shared
                    ;;
      "libunistring")
        ./configure --host=$TARGET_HOST \
                    --target=$TARGET_HOST \
                    --prefix=$PREFIX \
                    --with-libiconv-prefix=$LICO_DIR \
                    --disable-shared
                    ;;
      "libidn2")
        ./configure --host=$TARGET_HOST \
                    --target=$TARGET_HOST \
                    --prefix=$PREFIX \
                    --with-libunistring-prefix=$LUNI_DIR \
                    --with-libiconv-prefix=$LICO_DIR \
                    --disable-shared \
                    CFLAGS="$CFLAGS -I$LUNI_DIR/include -I$LICO_DIR/include -I$GT_DIR/include" \
                    LDFLAGS="$LDFLAGS -L$LUNI_DIR/lib -L$LICO_DIR/lib -L$GT_DIR/lib"
                    ;;
      "libpsl")
        ./autogen.sh
        ./configure --host=$TARGET_HOST \
                    --target=$TARGET_HOST \
                    --prefix=$PREFIX \
                    --disable-shared \
                    CFLAGS="$CFLAGS -I$LUNI_DIR/include -I$LIDN_DIR/include -I$LICO_DIR/include -I$GT_DIR/include" \
                    LDFLAGS="$LDFLAGS -L$LUNI_DIR/lib -L$LIDN_DIR/lib -L$LICO_DIR/lib -L$GT_DIR/lib"
                    ;;
      "brotli")
        ./bootstrap
        ./configure --host=$TARGET_HOST \
                    --target=$TARGET_HOST \
                    --prefix=$PREFIX \
                    --disable-shared
                    ;;
      "libexpat")
        cd expat
        ./buildconf.sh
        ./configure --host=$TARGET_HOST \
                    --target=$TARGET_HOST \
                    --prefix=$PREFIX \
                    --disable-shared
                    ;;
      "libmetalink")
        ./buildconf
        ./configure --host=$TARGET_HOST \
                    --target=$TARGET_HOST \
                    --prefix=$PREFIX \
                    --disable-shared \
                    CFLAGS="$CFLAGS -I$LEXP_DIR/include" \
                    LDFLAGS="$LDFLAGS -L$LEXP_DIR/lib"
                    ;;
      "c-ares")
        ./buildconf
        ./configure --host=$TARGET_HOST \
                    --target=$TARGET_HOST \
                    --prefix=$PREFIX \
                    --disable-shared
                    ;;
      "nghttp2")
        autoreconf -i
        ./configure --host=$TARGET_HOST \
                    --target=$TARGET_HOST \
                    --prefix=$PREFIX \
                    --disable-shared \
                    --without-systemd \
                    --without-jemalloc \
                    --enable-lib-only
                    ;;
      "curl")
        cp ../cacert.pem cacert.pem
        sed -i "s/\[unreleased\]/$(date +"%Y-%m-%d")/" include/curl/curlver.h
        sed -i "s/Release-Date/Build-Date/g" src/tool_help.c
        ./buildconf
        if $STATIC; then
          ./configure --host=$TARGET_HOST \
                      --target=$TARGET_HOST \
                      --prefix=$PREFIX \
                      --with-ssl=$BSSL_DIR \
                      --with-ca-path=/system/etc/security/cacerts \
                      --with-zlib=$ZLIB_DIR \
                      --with-brotli=$BROT_DIR \
                      --enable-ares=$LCA_DIR \
                      --with-nghttp2=$NGH2_DIR \
                      --enable-alt-svc \
                      --enable-ipv6 \
                      --enable-threaded-resolver \
                      --enable-hidden-symbols \
                      --enable-optimize \
                      --disable-versioned-symbols \
                      --disable-manual \
                      --disable-shared
        else
          ./configure --host=$TARGET_HOST \
                      --target=$TARGET_HOST \
                      --prefix=$PREFIX \
                      --with-ssl=$BSSL_DIR \
                      --with-ca-path=/system/etc/security/cacerts \
                      --with-zlib=$ZLIB_DIR \
                      --with-brotli=$BROT_DIR \
                      --enable-ares=$LCA_DIR \
                      --with-nghttp2=$NGH2_DIR \
                      --with-libssh2=$LSSH2_DIR \
                      --with-libmetalink=$LMET_DIR \
                      --with-libidn2=$LIDN_DIR \
                      --enable-alt-svc \
                      --enable-ipv6 \
                      --enable-threaded-resolver \
                      --enable-hidden-symbols \
                      --enable-optimize \
                      --disable-versioned-symbols \
                      --disable-manual \
                      --disable-shared \
                      CFLAGS="$CFLAGS -I$LPSL_DIR/include" \
                      LDFLAGS="$LDFLAGS -L$LPSL_DIR/lib"
                      # 
                      # --with-nghttp3=$NGH3_DIR \ goes with ngtcp2 or quiche
                      # --with-ngtcp2=$NGT2_DIR \ - only works if curl uses same openssl dev version (--with-ssl=$DIR/ngtcp2/openssl/build/openssl)
                      # --enable-tls-srp \ - works with openssl but not boringssl
                      # --enable-esni \ - not in openssl or boringssl yet
                      # --with-gssapi \ - krb5 won't compile
                      # quiche doesn't compile
                      # esni - not added to openssl or boringssl yet
                      # ldap - openldap won't compile
                      # sspi - windows only
        fi
        cp -f $DIR/local-configure.patch .
        sed -i "s/<TARGET_HOST>/$(echo $TARGET_HOST | sed "s/-linux/-unknown-linux/")/" local-configure.patch
        patch -p1 --no-backup-if-mismatch < local-configure.patch
        ;;
    esac

    rm -rf $DIR/build/$BIN/$LARCH 2>/dev/null; mkdir -p $DIR/build/$BIN/$LARCH
    if [ "$BIN" = "boringssl" ]; then
      ninja
      mkdir lib
      cp -f ssl/libssl.a crypto/libcrypto.a lib/
      cp -rf $PWD/../../include .
      cp -Rf $PWD/../$LARCH $DIR/build/$BIN/
    else
      unset FLAGS
      $STATIC && [ "$BIN" == "curl" ] && FLAGS=" curl_LDFLAGS=-all-static"
      make$FLAGS -j$JOBS
      [ "$BIN" == "openssl" ] && make install_sw || make install$FLAGS
      make clean
    fi
    cd $DIR/$BIN
  done
  cd $DIR
done

# Copy curl and depenencies to output directory - Note that Curl expects libz.so.1 while libssh2 expects libz.so
$STATIC && DEST=curl-static || DEST=curl-dynamic
rm -rf $DEST 2>/dev/null
for i in $ARCH; do
  case $i in
    "arm64"|"aarch64") mkdir -p $DEST/arm64-v8a/bin; cp -f build/curl/arm64-v8a/bin/curl $DEST/arm64-v8a/bin/; $STATIC || { mkdir $DEST/arm64-v8a/lib64; cp -f build/*/arm64-v8a/lib/*.so $DEST/arm64-v8a/lib64/; cp -f $DEST/arm64-v8a/lib64/libz.so $DEST/arm64-v8a/lib64/libz.so.1; };;
    "arm"|"armeabi"|"armeabi_v7a") mkdir -p $DEST/armeabi-v7a/bin; cp -f build/curl/armeabi-v7a/bin/curl $DEST/armeabi-v7a/bin/; $STATIC || { mkdir $DEST/armeabi-v7a/lib; cp -f build/*/armeabi-v7a/lib/*.so $DEST/armeabi-v7a/lib/; cp -f $DEST/armeabi-v7a/lib/libz.so $DEST/armeabi-v7a/lib/libz.so.1; };;
    "x86"|"i686") mkdir -p $DEST/x86/bin; cp -f build/curl/x86/bin/curl $DEST/x86/bin/; $STATIC || { mkdir $DEST/x86/lib; cp -f build/*/x86/lib/*.so $DEST/x86/lib/; cp -f $DEST/x86/lib/libz.so $DEST/x86/lib/libz.so.1; };;
    "x64"|"x86_64") mkdir -p $DEST/x86_64/bin; cp -f build/curl/x86_64/bin/curl $DEST/x86_64/bin/; $STATIC || { mkdir $DEST/x86_64/lib64; cp -f build/*/x86_64/lib/*.so $DEST/x86_64/lib64/; cp -f $DEST/x86_64/lib64/libz.so $DEST/x86_64/lib64/libz.so.1; };;
  esac
done

echo -e "\nOutput can be found in $DIR/$DEST\n"
