#!/bin/sh
OLD_DIR=$PWD
printenv ANDROID_NDK_ROOT > /dev/null || { echo please export ANDROID_NDK_ROOT=root_dir_of_your_android_ndk; exit 1; }
cd ./ffmpeg_src            || { echo please download ffmpeg source to [./ffmpeg_src];            exit 1; }

SYS_ROOT="$ANDROID_NDK_ROOT/platforms/android-8/arch-arm"
TOOL_CHAIN_DIR=`ls -d $ANDROID_NDK_ROOT/toolchains/arm-linux-androideabi-4.*/prebuilt/* | tail -n 1` || exit 1
LIBGCC_DIR=`ls -d $TOOL_CHAIN_DIR/lib/gcc/arm-linux-androideabi/4.* | tail -n 1` || exit 1
LIBEXEC_DIR=`ls -d $TOOL_CHAIN_DIR/libexec/gcc/arm-linux-androideabi/4.* | tail -n 1` || exit 1
CPP_ROOT=`ls -d $ANDROID_NDK_ROOT/sources/cxx-stl/gnu-libstdc++/4.* | tail -n 1` || exit 1
MAKE_DIR=`ls -d $ANDROID_NDK_ROOT/prebuilt/*/bin | tail -n 1` || exit 1
export  CFLAGS="-O3 --sysroot=$SYS_ROOT -I$SYS_ROOT/usr/include -I$LIBGCC_DIR/include -I$CPP_ROOT/include"
export LDFLAGS="-B$SYS_ROOT/usr/lib -B$LIBGCC_DIR -B$TOOL_CHAIN_DIR/arm-linux-androideabi/bin -B$LIBEXEC_DIR -B$CPP_ROOT/libs/armeabi"
export PATH="$TOOL_CHAIN_DIR/arm-linux-androideabi/bin:$LIBEXEC_DIR:$MAKE_DIR:$PATH"
export CC=gcc

echo ---------------make cpu-features lib--------------------
mkdir ./otherlib
gcc -c $CFLAGS $LDFLAGS $ANDROID_NDK_ROOT/sources/android/cpufeatures/cpu-features.c  -o ./otherlib/cpu-features.o || exit 1
echo ""; echo ok; echo ""

echo ---------------config ffmpeg [armv5]--------------------
#extra flags for webm/vp8 and h264
export  CFLAGS="$CFLAGS  -I./libvpx_src/qj_armv5/include -I./libx264_src/qj_armv5/include"
export LDFLAGS="$LDFLAGS -B./libvpx_src/qj_armv5/lib ./otherlib/cpu-features.o -B./libx264_src/qj_armv5/lib"
export CPPFLAGS="--sysroot=$SYS_ROOT"   #ubuntu NDK need this flag when check assembler by gcc \$CPPFLAGS \$ASFLAGS xxx.S which in turn cause "GNU assembler not found, install gas-preprocessor" due to "No include path for stdc-predef.h"

./configure --arch=arm --cpu=armv5te --target-os=linux --enable-cross-compile --enable-static --prefix=./qj_armv5 --disable-doc \
	--disable-ffplay --disable-ffprobe --disable-ffserver \
	--disable-symver --disable-debug \
	--disable-everything \
	\
	--enable-protocol=pipe \
	--enable-protocol=file \
	--enable-protocol=tcp \
	\
	--enable-demuxer=rawvideo --enable-decoder=rawvideo \
	\
	--enable-libvpx \
	--enable-muxer=webm --enable-encoder=libvpx* \
	--enable-demuxer=webm --enable-decoder=libvpx* \
	\
	--enable-libx264 --enable-gpl \
	--enable-muxer=mp4 --enable-encoder=libx264* \
	--enable-demuxer=mp4 --enable-decoder=libx264* \
	\
	--enable-filter=scale \
	--enable-filter=transpose \
	\
	--enable-muxer=image2 --enable-demuxer=image2 \
	--enable-encoder=png --enable-decoder=png \
	--enable-encoder=mjpeg --enable-decoder=mjpeg \
	--enable-muxer=mjpeg --enable-demuxer=mjpeg \
	\
	|| exit 1

echo ---------------make ffmpeg [armv5]--------------------
make clean
make all || exit 1
make install || exit 1

cp -fv ./qj_armv5/bin/ffmpeg $OLD_DIR/../bin/ffmpeg.armv5 || exit 1

echo ""; echo ok; echo ""