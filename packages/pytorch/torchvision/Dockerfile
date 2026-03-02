#---
# name: torchvision
# group: pytorch
# config: config.py
# depends: [pytorch, cmake]
# test: test.py
#---
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG TORCHVISION_VERSION \
    TORCH_CUDA_ARCH_LIST \
    FORCE_BUILD=off \
    FORCE_CUDA=1

COPY build.sh install.sh /tmp/torchvision/

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libjpeg-dev \
        libpng-dev \
        zlib1g-dev \
	&& rm -rf /var/lib/apt/lists/* \
	&& apt-get clean

RUN /tmp/torchvision/install.sh || /tmp/torchvision/build.sh
