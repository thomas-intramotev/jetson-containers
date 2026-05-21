#!/usr/bin/env bash
set -ex

apt update && apt install -y libcairo2-dev

cd /tmp

git clone --depth 1 --branch "${GSTREAMER_VERSION}" \
  https://gitlab.freedesktop.org/gstreamer/gstreamer.git

VENV_PATH=${VENV_PATH:-/opt/venv}
BASE_PREFIX="$("$VENV_PATH/bin/python" -c 'import sys; print(sys.base_prefix)')"
PY_VERSION="$("$VENV_PATH/bin/python" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"
PY_VERSION_NODOT="${PY_VERSION//.}"

# Set 'pure: false' when gst-python searches for python installation
sed -i -E '/pymod\.find_installation\(/{/pure[[:space:]]*:/!s/(pymod\.find_installation\(.*)\)/\1, pure: false)/}' \
  gstreamer/subprojects/gst-python/meson.build

# Configure call to Py_Initialize in gstpythonplugin.c to emulate uv-managed virtual environment
sed -i -E "s|^([[:space:]]*)Py_Initialize \(\);|\
\1PyConfig config;\n\
\1PyConfig_InitPythonConfig (\&config);\n\
\1PyConfig_SetString (\&config, \&config.executable, L\"${VENV_PATH}/bin/python\");\n\
\1PyConfig_SetString (\&config, \&config.prefix, L\"${VENV_PATH}\");\n\
\1PyConfig_SetString (\&config, \&config.exec_prefix, L\"${VENV_PATH}\");\n\
\1PyConfig_SetString (\&config, \&config.base_executable, L\"${BASE_PREFIX}/bin/python${PY_VERSION}\");\n\
\1PyConfig_SetString (\&config, \&config.base_prefix, L\"${BASE_PREFIX}\");\n\
\1PyConfig_SetString (\&config, \&config.base_exec_prefix, L\"${BASE_PREFIX}\");\n\
\1PyConfig_SetString (\&config, \&config.stdlib_dir, L\"${BASE_PREFIX}/lib/python${PY_VERSION}\");\n\
\1PyWideStringList_Append (\&config.module_search_paths, L\"${BASE_PREFIX}/lib/python${PY_VERSION_NODOT}.zip\");\n\
\1PyWideStringList_Append (\&config.module_search_paths, L\"${BASE_PREFIX}/lib/python${PY_VERSION}\");\n\
\1PyWideStringList_Append (\&config.module_search_paths, L\"${BASE_PREFIX}/lib/python${PY_VERSION}/lib-dynload\");\n\
\1PyWideStringList_Append (\&config.module_search_paths, L\"${VENV_PATH}/lib/python${PY_VERSION}/site-packages\");\n\
\1config.module_search_paths_set = 1;\n\
\1PyStatus status = Py_InitializeFromConfig (\&config);\n\
\1PyConfig_Clear (\&config);\n\
\1if (PyStatus_Exception (status)) {\n\
\1    g_critical (\"Py_InitializeFromConfig failed\");\n\
\1    return FALSE;\n\
\1}|" \
  gstreamer/subprojects/gst-python/plugin/gstpythonplugin.c
ln -s /tmp/gstreamer/subprojects/gst-python /tmp/pygobject/subprojects/gst-python

cd /tmp/pygobject

uv pip install \
  build \
  ninja \
  patchelf \
  pycairo \
  meson \
  meson-python

TRIPLET=$(dpkg-architecture -qDEB_HOST_MULTIARCH)
HOST_ARCH=$(dpkg-architecture -qDEB_HOST_ARCH)

# Symlink the uv-managed Python shared libraries into /opt/venv/lib (not strictly 
# necessary--we could point the meson build directly to LIBDIR--but this way the
# built library is not sensitive to e.g. hotfix Python updates which are reflected 
# in the uv-managed path)
PY_LIBDIR=$(python -c "import sysconfig; print(sysconfig.get_config_var('LIBDIR'))")
find "$PY_LIBDIR" -name 'libpython*so*' -exec ln -s {} /opt/venv/lib/ \;

meson setup _build \
  --buildtype=release \
  --prefix=/usr \
  --libdir=lib/$TRIPLET \
  -Dgst-python:libpython-dir=/opt/venv/lib
meson compile -C _build
DESTDIR="$PWD/_staging" meson install -C _build

patchelf --add-rpath "$PY_LIBDIR" \
  _staging/usr/lib/$TRIPLET/gstreamer-1.0/libgstpython.so

python -m build --wheel --no-isolation

mkdir -p _deb/usr/lib/$TRIPLET/gstreamer-1.0/ _deb/DEBIAN/
cp -r _staging/usr/lib/$TRIPLET/gstreamer-1.0/ _deb/usr/lib/$TRIPLET/

GST_MAJOR_MINOR=$(echo "${GSTREAMER_VERSION}" | sed -En "s/([0-9]+\.[0-9]+)(\.[0-9]+)*/\1/p")

cat > _deb/DEBIAN/control <<EOF
Package: gstreamer1.0-python${PY_VERSION}-plugin-loader
Version: ${GSTREAMER_VERSION}
Architecture: ${HOST_ARCH}
Maintainer: Thomas Kelly <thomas.kelly@intramotev.com>
Depends: libgstreamer1.0-0 (>= ${GST_MAJOR_MINOR})
Description: GStreamer plugin loader for uv-managed Python ${PY_VERSION}
  Embeds CPython ${PY_VERSION} into the GStreamer plugin scanner so that
  GStreamer elements written in Python can be loaded by C-only pipelines. Built 
  against the libpython${PY_VERSION} ABI; the plugin dlopens ${PY_VERSION}.so.1.0 
  at /opt/venv/lib, where the user must have symlinked the libpython shared objects 
  from uv-managed /root/.local/share/uv/python/<python-ver>/lib
EOF

mkdir -p debs
dpkg-deb --build _deb debs/gstreamer1.0-python${PY_VERSION}-plugin-loader_${GSTREAMER_VERSION}_${HOST_ARCH}.deb

uv pip install dist/*.whl
dpkg -i --force-depends debs/*.deb

twine upload --verbose dist/*.whl || echo "failed to upload wheel to ${TWINE_REPOSITORY_URL}"
tarpack upload gstreamer1.0-python${PY_VERSION}-plugin-loader_${GSTREAMER_VERSION} debs/ || \
  echo "failed to upload deb package tarball"