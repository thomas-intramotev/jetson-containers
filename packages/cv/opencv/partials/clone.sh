#!/usr/bin/env bash
set -ex
cd /opt

# install dependencies
bash $TMP/install_deps.sh

git clone --branch "${OPENCV_VERSION}" --recursive https://github.com/opencv/opencv \
  || git clone --recursive https://github.com/opencv/opencv

git clone --branch "${OPENCV_VERSION}" --recursive https://github.com/opencv/opencv_contrib \
  || git clone --recursive https://github.com/opencv/opencv_contrib

git clone --branch "${OPENCV_PYTHON}" --recursive https://github.com/opencv/opencv-python \
  || git clone --recursive https://github.com/opencv/opencv-python && export ENABLE_ROLLING=1

cd /opt/opencv-python/opencv || git checkout --recurse-submodules origin/4.x
git checkout --recurse-submodules ${OPENCV_VERSION} || git checkout --recurse-submodules origin/4.x
cat modules/core/include/opencv2/core/version.hpp
cd ../opencv_contrib
git checkout --recurse-submodules ${OPENCV_VERSION} || git checkout --recurse-submodules origin/4.x
cd ../opencv_extra
git checkout --recurse-submodules ${OPENCV_VERSION} || git checkout --recurse-submodules origin/4.x

cd ../

# apply patches to setup.py
git apply $TMP/patches.diff || echo "failed to apply git patches"
git diff

# OpenCV looks for the cuDNN version in cudnn_version.h, but it's been renamed to cudnn_version_v8.h
ln -sfnv /usr/include/$(uname -i)-linux-gnu/cudnn_version_v*.h /usr/include/$(uname -i)-linux-gnu/cudnn_version.h

# patches for FP16/half casts
function patch_opencv()
{
    sed -i 's|weight != 1.0|(float)weight != 1.0f|' opencv/modules/dnn/src/cuda4dnn/primitives/normalize_bbox.hpp
    sed -i 's|nms_iou_threshold > 0|(float)nms_iou_threshold > 0.0f|' opencv/modules/dnn/src/cuda4dnn/primitives/region.hpp
    grep 'weight' opencv/modules/dnn/src/cuda4dnn/primitives/normalize_bbox.hpp
    grep 'nms_iou_threshold' opencv/modules/dnn/src/cuda4dnn/primitives/region.hpp
}

patch_opencv
cd /opt
patch_opencv
cd /opt/opencv-python