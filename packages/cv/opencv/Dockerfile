#---
# name: opencv
# group: cv
# config: config.py
# depends: [cuda, cudastack:standard, python, numpy, opengl, vulkan, video-codec-sdk, ffmpeg]
# test: test.py
# notes: https://github.com/opencv/opencv-python
#---
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG OPENCV_VERSION \
    OPENCV_PYTHON \
    OPENCV_URL \
    CUDA_ARCH_BIN \
    ENABLE_CONTRIB=1 \
    FORWARD_CONTRIB=0 \
    FORCE_BUILD=off \
    TMP=/tmp/opencv

ENV OPENCV_VERSION=${OPENCV_VERSION} \
    OPENCV_URL=${OPENCV_URL}

ARG TAR_INDEX_URL
ENV TAR_INDEX_URL=${TAR_INDEX_URL}

# COPY clone.sh \
#      install_deps.sh \
#      $TMP/
# RUN cd $TMP && ./clone.sh

# COPY build_wheel.sh $TMP/
# RUN cd $TMP && ./build_wheel.sh

# COPY test.py $TMP/

# COPY install_and_upload_wheel.sh $TMP/
# RUN cd $TMP && ./install_and_upload_wheel.sh

# COPY build_deb.sh $TMP/
# RUN cd $TMP && ./build_deb.sh

COPY build.sh \
     install.sh \
     install_deps.sh \
     install_deb.sh \
     patches.diff \
     setup-stub.py \
     $TMP/

COPY test.py $TMP/

RUN cd $TMP && ./install.sh || ./build.sh

RUN if [ ! -f "$TMP/.opencv" ]; then \
      echo "FAILED to install OpenCV $OPENCV_VERSION"; \
      exit 1; \
    fi
