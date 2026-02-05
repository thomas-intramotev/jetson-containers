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

RUN if [ "${FORCE_BUILD}" = "on" ]; then \
        cd /opt && \
        (git clone --branch "${OPENCV_VERSION}" --recursive https://github.com/opencv/opencv \
            || git clone --recursive https://github.com/opencv/opencv \
            || echo "Failed to pre-clone opencv") && \
        (git clone --branch "${OPENCV_VERSION}" --recursive https://github.com/opencv/opencv_contrib \
            || git clone --recursive https://github.com/opencv/opencv_contrib \
            || echo "Failed to pre-clone opencv_contrib") && \
        (git clone --branch "${OPENCV_PYTHON}" --recursive https://github.com/opencv/opencv-python \
            || (git clone --recursive https://github.com/opencv/opencv-python && touch opencv-python/.enable_rolling) \
            || echo "Failed to pre-clone opencv-python"); \
    fi

COPY build.sh \
     install.sh \
     install_deps.sh \
     install_deb.sh \
     patches.diff \
     setup-stub.py \
     $TMP/

COPY test.py $TMP/

ARG CACHE_BUILD=off
RUN --mount=type=cache,target=/opt/opencv/build \
    if [ ! "${CACHE_BUILD}" = "on" ]; then \
        rm -rf /opt/opencv/build/*; \
    fi && \
    cd $TMP && ./install.sh || ./build.sh

RUN if [ ! -f "$TMP/.opencv" ]; then \
      echo "FAILED to install OpenCV $OPENCV_VERSION"; \
      exit 1; \
    fi
