#!/usr/bin/env bash
set -ex

if [ "${FORCE_BUILD}" = "on" ]; then
   echo "Forcing build of gstreamer Python bindings"
   exit 1
fi

UV_PY_VERSION="$(python -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"

if [ "${PYGOBJECT_INSTALL_METHOD}" = "pip" ]; then
  echo "Installing pygobject from pip"
  uv pip install \
    PyGObject${PYGOBJECT_VERSION:+~=${PYGOBJECT_VERSION}} \
    pycairo${PYCAIRO_VERSION:+~=${PYCAIRO_VERSION}}

  if [ -z "$GST_PY_PLUGIN_URL" ]; then
    GST_PY_PLUGIN_DEB="gstreamer1.0-python${UV_PY_VERSION}-plugin-loader_${GSTREAMER_VERSION}.tar.gz"
    GST_PY_PLUGIN_URL="${TAR_INDEX_URL}/${GST_PY_PLUGIN_DEB}"
  else
    GST_PY_PLUGIN_DEB="$(basename ${GST_PY_PLUGIN_URL})"
  fi
  echo "Installing Gstreamer Python plugin loader from ${GST_PY_PLUGIN_URL}"

  PY_LIBDIR=$(python -c "import sysconfig; print(sysconfig.get_config_var('LIBDIR'))")
  find "$PY_LIBDIR" -name 'libpython*so*' -exec ln -s {} /opt/venv/lib/ \;

  mkdir -p /tmp/gst_py_plugin
  if wget $WGET_FLAGS "${GST_PY_PLUGIN_URL}" -O "/tmp/gst_py_plugin/${GST_PY_PLUGIN_DEB}"; then
    tar -xzf "/tmp/gst_py_plugin/${GST_PY_PLUGIN_DEB}" -C /tmp/gst_py_plugin
    dpkg -i --force-depends /tmp/gst_py_plugin/*.deb
  else
    echo "Failed to download gstreamer Python plugin loader from ${GST_PY_PLUGIN_URL}"
  fi
else
  apt update && apt install -y \
    python3-gi \
    python3-gst-1.0 \
    gstreamer1.0-python3-plugin-loader

  SYS_PY_VERSION="$(/usr/bin/python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"
  if [ "${UV_PY_VERSION}" != "${SYS_PY_VERSION}" ]; then
    echo "WARNING: System Python version ${SYS_PY_VERSION} does not match UV Python version ${UV_PY_VERSION}"
    echo "Cannot symlink gstreamer packages from system Python to UV Python due to ABI mismatch"
  else
    ln -s /usr/lib/python3/dist-packages/gi /opt/venv/lib/python3.*/site-packages/
  fi

  uv pip install pycairo${PYCAIRO_VERSION:+~=${PYCAIRO_VERSION}}
fi
