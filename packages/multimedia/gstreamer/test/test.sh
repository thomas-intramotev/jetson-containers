#!/usr/bin/env bash
set -e

echo "TESTING gstreamer..."

gst-inspect-1.0 --version
gst-inspect-1.0 > /dev/null || (echo "gst-inspect-1.0 failed" && exit 1)
gst-inspect-1.0 nvvideo4linux2 > /dev/null || \
  (echo "gst-inspect-1.0 failed to find nvvideo4linux2 plugin" && exit 1)
gst-inspect-1.0 nvarguscamerasrc > /dev/null || \
  (echo "gst-inspect-1.0 failed to find nvarguscamerasrc plugin" && exit 1)

echo "SUCCESS gstreamer"

echo "TESTING gst-python..."

python test_bindings.py

echo "SUCCESS gst-python"

echo "TESTING Python plugin loader..."

# Install test plugin and clear gstreamer cache to force re-discovery of plugins
mkdir -p /usr/lib/aarch64-linux-gnu/gstreamer-1.0/python
cp test_py_plugin.py /usr/lib/aarch64-linux-gnu/gstreamer-1.0/python/
rm -rf ~/.cache/gstreamer-1.0

gst-inspect-1.0 python || \
  (echo "gst-inspect-1.0 failed to find python plugin" && exit 1)
gst-inspect-1.0 pylogger || \
  (echo "gst-inspect-1.0 failed to find custom pylogger plugin" && exit 1)

gst-launch-1.0 -v \
    videotestsrc num-buffers=30 ! \
    video/x-raw,width=1280,height=720,framerate=30/1,format=I420 ! \
    nvvidconv ! \
    'video/x-raw(memory:NVMM),format=NV12' ! \
    nvv4l2h264enc ! \
    h264parse ! \
    pylogger ! \
    matroskamux ! \
    filesink location=/tmp/test.mkv
gst-launch-1.0 filesrc location=/tmp/test.mkv ! decodebin ! fakesink || \
  (echo "gst-launch-1.0 failed to run pipeline with custom python plugin" && exit 1)

echo "SUCCESS Python plugin loader"

echo "TESTING end-to-end pipeline..."

python test_pipeline.py

echo "SUCCESS end-to-end pipeline"