#!/usr/bin/env bash
echo "Building opencv-python ${OPENCV_VERSION}"
set -ex
cd /opt/opencv-python

# default build flags
OPENCV_BUILD_ARGS="\
   -DCPACK_BINARY_DEB=ON \
   -DBUILD_EXAMPLES=OFF \
   -DBUILD_opencv_python2=OFF \
   -DBUILD_opencv_python3=ON \
   -DBUILD_opencv_java=OFF \
   -DCMAKE_BUILD_TYPE=RELEASE \
   -DCMAKE_INSTALL_PREFIX=/usr/local \
   -DWITH_FFMPEG=ON \
   -DCUDA_ARCH_BIN=${CUDA_ARCH_BIN} \
   -DCUDA_ARCH_PTX= \
   -DCUDA_FAST_MATH=ON \
   -DCUDNN_INCLUDE_DIR=/usr/include/$(uname -i)-linux-gnu \
   -DEIGEN_INCLUDE_PATH=/usr/include/eigen3 \
   -DWITH_EIGEN=ON \
   -DOPENCV_DNN_CUDA=ON \
   -DOPENCV_ENABLE_NONFREE=ON \
   -DOPENCV_GENERATE_PKGCONFIG=ON \
   -DOpenGL_GL_PREFERENCE=GLVND \
   -DWITH_CUBLAS=ON \
   -DWITH_CUDA=ON \
   -DWITH_CUDNN=ON \
   -DWITH_GSTREAMER=ON \
   -DWITH_LIBV4L=ON \
   -DWITH_GTK=ON \
   -DWITH_OPENGL=ON \
   -DWITH_OPENCL=OFF \
   -DWITH_IPP=OFF \
   -DWITH_TBB=ON \
   -DBUILD_TIFF=ON \
   -DBUILD_PERF_TESTS=OFF \
   -DBUILD_TESTS=OFF"

# # TODO: Don't know exactly what I changed to require this
# if [ true ]; then
#   OPENCV_BUILD_ARGS="${OPENCV_BUILD_ARGS} -DPYTHON3_LIMITED_API=ON"
# fi

# architecture-specific build flags
if [ "$(uname -m)" == "aarch64" ]; then
    OPENCV_BUILD_ARGS="${OPENCV_BUILD_ARGS} -DENABLE_NEON=ON"
fi

# cv2.abi3.so: undefined symbol: glRenderbufferStorageEXT
# https://github.com/opencv/opencv_contrib/issues/2307
OPENCV_BUILD_ARGS="${OPENCV_BUILD_ARGS} -DBUILD_opencv_rgbd=OFF"

# setup environment and build wheel
export CMAKE_BUILD_PARALLEL_LEVEL=$(nproc)
export CMAKE_POLICY_VERSION_MINIMUM="3.5"
export CMAKE_LIBRARY_PATH=/usr/local/cuda/lib64/stubs
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
export ENABLE_CONTRIB=1
# export ENABLE_ROLLING=1 # Build from last commit

CREATED_SYMLINKS=""

setup_symlink() {
    local target="$1"
    local link_name="$2"
    
    if [ ! -e "$link_name" ]; then
        ln -s "$target" "$link_name"
        CREATED_SYMLINKS="$CREATED_SYMLINKS $link_name"
    else
        echo "CUDA symlink or library already exists: $link_name"
    fi
}

setup_symlink "${CMAKE_LIBRARY_PATH}/libcuda.so" "${CMAKE_LIBRARY_PATH}/libcuda.so.1"
setup_symlink "${CMAKE_LIBRARY_PATH}/libcuda.so" "${CMAKE_LIBRARY_PATH}/../libcuda.so"
setup_symlink "${CMAKE_LIBRARY_PATH}/libcuda.so.1" "${CMAKE_LIBRARY_PATH}/../libcuda.so.1"

# Install dependencies for building the wheel
uv pip install scikit-build
uv pip install --force-reinstall numpy >2

cat <<EOF > /opt/opencv-python/cv2/version.py
opencv_version = "${OPENCV_VERSION}"
contrib = True
headless = False
rolling = False
EOF
CMAKE_ARGS="${OPENCV_BUILD_ARGS} -DOPENCV_EXTRA_MODULES_PATH=/opt/opencv-python/opencv_contrib/modules" \
OPENCV_PYTHON_SKIP_GIT_COMMANDS=1 \
uv build --wheel --out-dir /opt --verbose --no-build-isolation .
ls /opt

for link in $CREATED_SYMLINKS; do
    rm "$link"
done