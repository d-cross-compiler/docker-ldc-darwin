#!/bin/bash

set -xeuo pipefail

ROOTFS='/rootfs'
MACOSX_SDK_ROOT="/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk"

install_dependecies() {
  apt update
  apt install -y xz-utils libxml2 curl clang-11
}

setup_ldc() {
  curl -L -o ldc2-linux.tar.xz "https://github.com/ldc-developers/ldc/releases/download/v$LDC_VERSION/ldc2-$LDC_VERSION-linux-$ARCH.tar.xz"
  tar xf ldc2-linux.tar.xz

  curl -L -o ldc2-osx.tar.xz "https://github.com/ldc-developers/ldc/releases/download/v$LDC_VERSION/ldc2-$LDC_VERSION-osx-$ARCH.tar.xz"
  tar xf ldc2-osx.tar.xz
  mv "ldc2-$LDC_VERSION-osx-$ARCH" ldc2-osx

  rm -rf ldc2-osx/bin/*
  cp "ldc2-$LDC_VERSION-linux-$ARCH/bin"/* ldc2-osx/bin

  cat <<EOF > ldc2-osx/etc/ldc2.conf
default:
{
    // default switches injected before all explicit command-line switches
    switches = [
        "-defaultlib=phobos2-ldc,druntime-ldc",
        "--mtriple=x86_64-apple-macos",
        "-Xcc=-target",
        "-Xcc=x86_64-apple-macos",
        "-Xcc=-mmacosx-version-min=10.9",
        "-Xcc=-isysroot",
        "-Xcc=$MACOSX_SDK_ROOT",
    ];
    // default switches appended after all explicit command-line switches
    post-switches = [
        "-I%%ldcbinarypath%%/../import",
    ];
    // default directories to be searched for libraries when linking
    lib-dirs = [
        "%%ldcbinarypath%%/../lib",
    ];
    // default rpath when linking against the shared default libs
    rpath = "%%ldcbinarypath%%/../lib";
};
EOF

  local ldc_target_path="$ROOTFS/opt/ldc"

  mkdir -p "$ldc_target_path/bin"
  mv \
    ldc2-osx/bin/dub \
    ldc2-osx/bin/ldc2 \
    ldc2-osx/bin/ldmd2 \
    ldc2-osx/bin/rdmd \
    "$ldc_target_path/bin"

  mv \
    ldc2-osx/etc \
    ldc2-osx/import \
    ldc2-osx/lib \
    ldc2-osx/LICENSE \
    ldc2-osx/README \
    "$ldc_target_path"
}

setup_macosx_sdk() {
  curl -L -o macosx-sdk.tar.xz "https://github.com/d-cross-compiler/sdk-apple/releases/download/v$MACOSX_SDK_PREFIX/macosx-$MACOSX_SDK_PREFIX-$MACOSX_SDK_VERSION.tar.xz"
  mkdir -p "$ROOTFS/$MACOSX_SDK_ROOT"
  tar xf macosx-sdk.tar.xz
  cp -r "macosx-$MACOSX_SDK_PREFIX-$MACOSX_SDK_VERSION"/* "$ROOTFS/$MACOSX_SDK_ROOT/"
}

setup_linker() {
  curl -L -o ld64.tar.xz "https://github.com/d-cross-compiler/cctools-port/releases/download/cctools-$CCTOOLS_VERSION-ld64-$LD64_VERSION/ld64-$LD64_VERSION-linux-x86_64.tar.xz"
  tar xf ld64.tar.xz
  mkdir -p "$ROOTFS/usr/bin"
  mv ld "$ROOTFS/usr/bin"
}

setup_rootfs() {
  mkdir -p "$ROOTFS/usr/bin"
  cp /usr/bin/clang-11 "$ROOTFS/usr/bin/cc"

  mkdir -p "$ROOTFS/lib/llvm-11/lib"
  cp /lib/llvm-11/lib/libclang-cpp.so.11 "$ROOTFS/lib/llvm-11/lib"

  mkdir -p "$ROOTFS/lib64"
  cp /lib64/ld-linux-x86-64.so.2 "$ROOTFS/lib64"

  mkdir -p "$ROOTFS/lib/x86_64-linux-gnu"
  cp \
    /lib/x86_64-linux-gnu/ld-2.31.so \
    /lib/x86_64-linux-gnu/libbsd.so.0 \
    /lib/x86_64-linux-gnu/libbsd.so.0.10.0 \
    /lib/x86_64-linux-gnu/libc-2.31.so \
    /lib/x86_64-linux-gnu/libc.so.6 \
    /lib/x86_64-linux-gnu/libclang-cpp.so.11 \
    /lib/x86_64-linux-gnu/libdl.so.2 \
    /lib/x86_64-linux-gnu/libedit.so.2 \
    /lib/x86_64-linux-gnu/libedit.so.2.0.63 \
    /lib/x86_64-linux-gnu/libffi.so.7 \
    /lib/x86_64-linux-gnu/libffi.so.7.1.0 \
    /lib/x86_64-linux-gnu/libgcc_s.so.1 \
    /lib/x86_64-linux-gnu/libicudata.so.66 \
    /lib/x86_64-linux-gnu/libicudata.so.66.1 \
    /lib/x86_64-linux-gnu/libicuuc.so.66 \
    /lib/x86_64-linux-gnu/libicuuc.so.66.1 \
    /lib/x86_64-linux-gnu/libLLVM-11.so.1 \
    /lib/x86_64-linux-gnu/liblzma.so.5 \
    /lib/x86_64-linux-gnu/liblzma.so.5.2.4 \
    /lib/x86_64-linux-gnu/libm-2.31.so \
    /lib/x86_64-linux-gnu/libm.so.6 \
    /lib/x86_64-linux-gnu/libpcre2-8.so.0 \
    /lib/x86_64-linux-gnu/libpcre2-8.so.0.9.0 \
    /lib/x86_64-linux-gnu/libpthread-2.31.so \
    /lib/x86_64-linux-gnu/libpthread.so.0 \
    /lib/x86_64-linux-gnu/librt-2.31.so \
    /lib/x86_64-linux-gnu/librt.so.1 \
    /lib/x86_64-linux-gnu/libselinux.so.1 \
    /lib/x86_64-linux-gnu/libstdc++.so.6 \
    /lib/x86_64-linux-gnu/libstdc++.so.6.0.28 \
    /lib/x86_64-linux-gnu/libtinfo.so.6 \
    /lib/x86_64-linux-gnu/libtinfo.so.6.2 \
    /lib/x86_64-linux-gnu/libxml2.so.2 \
    /lib/x86_64-linux-gnu/libxml2.so.2.9.10 \
    /lib/x86_64-linux-gnu/libz.so.1 \
    /lib/x86_64-linux-gnu/libz.so.1.2.11 \
    "$ROOTFS/lib/x86_64-linux-gnu"
}

install_dependecies
setup_ldc
setup_macosx_sdk
setup_linker
setup_rootfs
