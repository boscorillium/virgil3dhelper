#!/bin/bash

run_vtest_server() {
    virglrenderer/vtest/vtest_server
}

sudo yum install -y python-mako gcc-c++ libepoxy-devel mesa-libEGL-devel mesa-libgbm-devel && sudo yum-builddep -y mesa

git clone -b egl-mesa-drm-buf-export git://people.freedesktop.org/~airlied/mesa host_mesa
git clone git://people.freedesktop.org/~airlied/virglrenderer
git clone -b virgl-mesa-driver git://people.freedesktop.org/~airlied/mesa guest_mesa
git clone -b virtgpu https://github.com/boscorillium/libdrm.git 

cd host_mesa
./autogen.sh --enable-dri-drivers --enable-glx-tls --enable-gles2 --with-egl-platforms=x11,wayland,drm --prefix=/usr
make -j && sudo make install
cd ..

sudo cp libdrm/include/drm/virtgpu_drm.h /usr/include/libdrm

cd guest_mesa
./autogen.sh --with-dri-drivers= --with-gallium-drivers=virgl,swrast --enable-debug --enable-llvm-shared-libs --enable-glx-tls \
--enable-gles2 --with-egl-platforms=x11,wayland,drm --enable-texture-float --prefix=/opt/virgl 
make -j && sudo make install

cd ../virglrenderer
./autogen.sh
sed -e 's/@CODE_COVERAGE_RULES@//g' Makefile > Makefile.tst && mv Makefile.tst Makefile
make -j && sudo make install

cd ..
run_vtest_server &

GALLIUM_DRIVER=virpipe LIBGL_ALWAYS_SOFTWARE=y LD_LIBRARY_PATH=/opt/virgl/lib LIBGL_DRIVERS_PATH=/opt/virgl/lib/dri LIBGL_DEBUG=verbose glxinfo |grep OpenGL
