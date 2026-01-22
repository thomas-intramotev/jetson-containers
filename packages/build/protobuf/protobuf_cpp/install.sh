#!/usr/bin/env bash
set -ex

PROTOBUF_URL=https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOBUF_VERSION}
PROTOBUF_DIR=protobuf-${PROTOBUF_VERSION}
PROTOC_DIR=protoc-${PROTOBUF_VERSION}-linux-aarch_64

apt-get update
apt-get install -y --no-install-recommends \
		build-essential \
		autoconf \
		automake \
		libtool \
		cmake \
		ninja-build \
		zip \
		unzip
rm -rf /var/lib/apt/lists/*
apt-get clean

uv pip install tzdata
uv pip install 'setuptools<72'  # setup.py invalid command 'test'

cd /tmp

wget $WGET_FLAGS $PROTOBUF_URL/$PROTOBUF_DIR.zip
wget $WGET_FLAGS $PROTOBUF_URL/$PROTOC_DIR.zip

unzip ${PROTOBUF_DIR}.zip -d ${PROTOBUF_DIR}
unzip ${PROTOC_DIR}.zip -d ${PROTOC_DIR}

cp ${PROTOC_DIR}/bin/protoc /usr/local/bin/protoc
cd ${PROTOBUF_DIR}/protobuf-${PROTOBUF_VERSION}

# Check if autogen.sh exists (older versions) or use CMake (newer versions)
if [ -f "./autogen.sh" ]; then
	./autogen.sh
	./configure --prefix=/usr/local
	make -j$(nproc)
	make check -j$(nproc)
	make install
else
	# Use CMake for newer protobuf versions (3.20+)
	mkdir -p build
	cd build
	cmake .. \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX=/usr/local \
		-DCMAKE_CXX_STANDARD=17 \
		-DCMAKE_CXX_STANDARD_REQUIRED=ON \
		-Dprotobuf_BUILD_TESTS=ON \
		-Dprotobuf_BUILD_SHARED_LIBS=ON
	cmake --build . -j$(nproc)
	ctest -j$(nproc)
	cmake --install .
	cd ..
fi
ldconfig

# Build Python bindings with C++ implementation
# Older releases can build via setuptools, while newer releases require bazel
if [ -d "python" ] && [ -f "python/setup.py" ]; then
	cd python
	python3 setup.py build --cpp_implementation
	python3 setup.py test --cpp_implementation
	python3 setup.py bdist_wheel --cpp_implementation

	cp dist/*.whl /opt
	cd ..
elif [ -d "python/dist" ] && [ -f "python/dist/setup.py" ]; then
	bazel build //python/dist:binary_wheel --cpu "linux-aarch_64"
	cp bazel-bin/python/dist/*.whl /opt
else
	echo "Warning: python directory or setup.py not found, skipping Python bindings build"
fi

if ls /opt/protobuf*.whl 1> /dev/null 2>&1; then
	uv pip install /opt/protobuf*.whl
	if [ "$UPLOAD_WHEEL" = "on" ]; then
		twine upload --verbose /opt/protobuf*.whl || echo "failed to upload wheel to ${TWINE_REPOSITORY_URL}"
	fi
fi

# Return to /tmp for cleanup
cd /tmp
rm ${PROTOBUF_DIR}.zip
rm ${PROTOC_DIR}.zip
rm -rf ${PROTOBUF_DIR}
rm -rf ${PROTOC_DIR}

#python3 setup.py install --cpp_implementation && \
#uv pip install protobuf==${PROTOBUF_VERSION} --install-option="--cpp_implementation"
#uv pip show protobuf && protoc --version
