#!/usr/bin/env bash
set -ex

apt update && apt install -y libcairo2-dev

cd /tmp
git clone --depth 1 --branch "${GST_PYTHON_VERSION}" \
  https://gitlab.freedesktop.org/gstreamer/gstreamer.git
# Set 'pure: false' when gst-python searches for python installation
sed -i -E '/pymod\.find_installation\(/{/pure[[:space:]]*:/!s/(pymod\.find_installation\(.*)\)/\1, pure: false)/}' \
  gstreamer/subprojects/gst-python/meson.build
ln -s /tmp/gstreamer/subprojects/gst-python /tmp/pygobject/subprojects/gst-python

uv pip install build

cd /tmp/pygobject