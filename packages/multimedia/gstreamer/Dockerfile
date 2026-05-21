#---
# name: gstreamer
# group: multimedia
# depends: opencv
# test: [test.sh, test.py]
#---
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG GSTREAMER_VERSION \
    PYGOBJECT_VERSION \
    OPENCV_VERSION \
    OPENCV_URL \
    GST_PY_PLUGIN_URL \
    WGET_FLAGS \
    PYGOBJECT_INSTALL_METHOD=apt \
    FORCE_BUILD=off \
    REINSTALL_OPENCV=on \
    OPENCV_ENABLE_CONTRIB=1 \
    OPENCV_FORWARD_CONTRIB=0 \
    OPENCV_FORCE_BUILD=off \
    OPENCV_TMP=/tmp/opencv

# gstreamer1.0-plugins-bad depend on the ubuntu version of opencv, and will fail to install
# if opencv_cuda is already installed (so remove it and re-install it again after)
RUN apt-get update && \
    apt-get purge -y '*opencv*' || echo "existing OpenCV installation not found" && \
    apt-get install -y --no-install-recommends \
      lsb-release \
      libunwind-dev \
      gir1.2-glib-2.0 \
      libgirepository1.0-dev \
      libgstreamer1.0-dev \
      gstreamer1.0-tools \
      gstreamer1.0-libav \
      gstreamer1.0-rtsp \
      gstreamer1.0-plugins-good \
      gstreamer1.0-plugins-bad \
      gstreamer1.0-plugins-ugly \
      gstreamer1.0-nice \
      libgstreamer-plugins-base1.0-dev \
      libgstreamer-plugins-good1.0-dev \
      libgstreamer-plugins-bad1.0-dev \
      libgstrtspserver-1.0-0 \
      libnss-mdns \
      avahi-utils \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

COPY pygobject/ /tmp/pygobject
RUN find /tmp/pygobject -type f | xargs sed -i "s/_PYGOBJECT_VERSION_/${PYGOBJECT_VERSION}/g"

COPY build.sh install.sh /tmp/pygobject/
RUN chmod +x /tmp/pygobject/build.sh /tmp/pygobject/install.sh
RUN /tmp/pygobject/install.sh || /tmp/pygobject/build.sh

# Stage opencv args as env vars, with the names that ${OPENCV_TMP}/install.sh expects
ENV OPENCV_VERSION=${OPENCV_VERSION} \
    OPENCV_URL=${OPENCV_URL} \
    ENABLE_CONTRIB=${OPENCV_ENABLE_CONTRIB} \
    FORWARD_CONTRIB=${OPENCV_FORWARD_CONTRIB} \
    FORCE_BUILD=${OPENCV_FORCE_BUILD} \
    TMP=${OPENCV_TMP}

# re-install opencv and make a copy of these gstreamer headers (some of them get purged)
RUN if [ "${REINSTALL_OPENCV}" = "on" ]; then \
    cp -r /usr/include/gstreamer-1.0 /tmp && \
    (mv ${OPENCV_TMP}/opencv-python/setup.py ${OPENCV_TMP}/setup-stub.py || true) && \
    ${OPENCV_TMP}/install.sh && \
    cp -r /tmp/gstreamer-1.0 /usr/include && \
    rm -rf /tmp/gstreamer-1.0 && \
    ln -s /usr/lib/$(uname -m)-linux-gnu/libgstwebrtc-1.0.so.0 /usr/lib/$(uname -m)-linux-gnu/libgstwebrtc-1.0.so || \
    echo "libgstwebrtc already setup" ; \
    else echo "skipping OpenCV re-installation"; fi

ENV OPENCV_VERSION= \
    OPENCV_URL= \
    ENABLE_CONTRIB= \
    FORWARD_CONTRIB= \
    FORCE_BUILD= \
    TMP=