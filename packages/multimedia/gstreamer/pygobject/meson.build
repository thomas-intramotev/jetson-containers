project(
  'pygobject-bundled-gst',
  'c',
  version: '_PYGOBJECT_VERSION_',
  meson_version: '>= 1.2',
  license: 'LGPL-2.1-or-later',
)

# ---------------------------------------------------------------------------
# PyGObject
# ---------------------------------------------------------------------------
# Build pygobject in "wheel mode":
#
#   * `wheel=true` suppresses the install of pygobject-3.0.pc and the
#     hand-rolled METADATA / dist-info that pygobject normally drops
#     into site-packages. Both would either escape a wheel's payload
#     boundary or collide with the dist-info that meson-python
#     generates for the top-level project.
#
#   * `tests=true` would pull in gobject-introspection-tests as a
#     subproject and add test targets we don't need in a release wheel.
#
# Using `default_options` on the subproject() call scopes these settings
# to pygobject only, so this top-level project doesn't need to declare
# a matching `wheel` or `tests` option.
subproject(
  'pygobject',
  default_options: [
    'wheel=true',
    'tests=false',
  ],
)

# ---------------------------------------------------------------------------
# gst-python (subtree from the gstreamer monorepo's subprojects/gst-python)
# ---------------------------------------------------------------------------
# gst-python's gi/overrides/meson.build installs Gst.py, GstApp.py,
# GstAudio.py, GstVideo.py, GstAnalytics.py, GstPbutils.py and the
# _gi_gst / _gi_gst_analytics C extensions into the SAME
# python.get_install_dir(pure: false) / 'gi/overrides' that pygobject
# above is also populating. meson-python then collects the merged
# DESTDIR into a single wheel.
#
# gst-python resolves its pygobject build-time dependency via:
#   pygobject_dep = dependency('pygobject-3.0',
#                              fallback: ['pygobject', 'pygobject_dep'],
#                              version: '>= 3.8')
# Because the pygobject subproject is already loaded above, the
# fallback returns pygobject's in-tree `pygobject_dep` variable (its
# include directories + gobject_dep + ffi_dep). No system
# libpygobject-dev or pygobject-3.0.pc is required at build time.
#
# gst-python's other dependencies (gstreamer-1.0, gstreamer-base-1.0,
# gmodule-2.0, optionally gstreamer-bad-1.0 for GstAnalytics) MUST be
# present at build time via pkg-config; install them with
#   apt install libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
#               libgstreamer-plugins-bad1.0-dev libglib2.0-dev
subproject('gst-python')
