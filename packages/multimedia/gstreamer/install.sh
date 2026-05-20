#!/usr/bin/env bash
set -ex

if [ "${FORCE_BUILD}" = "on" ]; then
   echo "Forcing build of gstreamer Python bindings"
   exit 1
fi

