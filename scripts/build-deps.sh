set -e

BASE_FFMPEG_ARGS="--enable-pic --enable-static --disable-shared --disable-all --enable-avcodec --enable-decoder=h264 --enable-decoder=hevc --enable-libdrm --enable-decoder=h264_v4l2m2m --enable-decoder=hevc_v4l2m2m --extra-cflags=-I/usr/include/libdrm"

echo "Building dependencies for $TARGET"
if [ "$TARGET" == "rpi" ] || [ "$TARGET" == "rpi64" ]; then
    # We have to build MMAL libraries for aarch64
    if [ "$TARGET" == "rpi64" ]; then
        cd /opt/rpi-userland
        mkdir build
        cd build
        cmake -DARM64=ON -DLIBRARY_TYPE=STATIC -DVCOS_PTHREADS_BUILD_SHARED=OFF ..
        make -j$(nproc)
        make install

        # We also have to patch the FFmpeg configure script since it doesn't use pkg-config
        sed -i 's|add_ldflags -L/opt/vc/lib/|add_ldflags -L/opt/vc/lib/ -pthread|g' /opt/FFmpeg/configure
    fi

    # Copy libraspberrypi-dev pkgconfig files into the default location
    mkdir -p /usr/local/lib/pkgconfig
    cp /opt/vc/lib/pkgconfig/* /usr/local/lib/pkgconfig/
    # Enable MMAL and VL42 stateless decoders
    EXTRA_FFMPEG_ARGS="--enable-mmal --enable-decoder=h264_mmal --disable-rpi --enable-sand --enable-libudev --enable-v4l2-request --enable-hwaccel=h264_v4l2request --enable-hwaccel=hevc_v4l2request"
elif [ "$TARGET" == "l4t" ]; then
    # Enable NVV4L2 decoders
    EXTRA_FFMPEG_ARGS="--enable-nvv4l2 --enable-decoder=h264_nvv4l2 --enable-decoder=hevc_nvv4l2"
elif [ "$TARGET" == "desktop" ]; then
    # We need to install the NVDEC headers
    cd /opt/nv-codec-headers
    make install

    # Enable VAAPI, VDPAU, and NVDEC decoders
    EXTRA_FFMPEG_ARGS="--enable-nvdec --enable-hwaccel=h264_nvdec --enable-hwaccel=hevc_nvdec --enable-hwaccel=h264_vaapi --enable-hwaccel=hevc_vaapi --enable-hwaccel=h264_vdpau --enable-hwaccel=hevc_vdpau"
else
    echo "Unrecognized target: $TARGET"
    exit 1
fi

# Build and install our SDL2 build
cd /opt/SDL2
./configure --enable-static --disable-shared --enable-video-kmsdrm --disable-video-rpi
make -j$(nproc)
cat sdl2.pc
make install

# Build and install SDL_ttf
# Since we'll be linking statically, we need to use Libs.private instead of Libs, but
# there's no way to tell QMake to use the Libs.private section, so we have to replace
# Libs with Libs.private ourselves prior to installation.
cd /opt/SDL_ttf
./configure --enable-static --disable-shared
make -j$(nproc)
sed -i 's/-lSDL2_ttf/-lSDL2_ttf -lfreetype/g' SDL2_ttf.pc
cat SDL2_ttf.pc
make install

cd /opt/FFmpeg
./configure $BASE_FFMPEG_ARGS $EXTRA_FFMPEG_ARGS
make -j$(nproc)
make install

if [ "$TARGET" == "l4t" ]; then
    # Patch libavcodec.pc to provide the proper library path for libnvbuf_utils.so
    sed -i 's|-lnvbuf_utils|-L/usr/lib/aarch64-linux-gnu/tegra/ -lnvbuf_utils|g' /usr/local/lib/pkgconfig/libavcodec.pc
    cat /usr/local/lib/pkgconfig/libavcodec.pc
fi
