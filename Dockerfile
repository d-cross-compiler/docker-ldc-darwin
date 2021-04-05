FROM ubuntu:20.04 AS builder

ARG LDC_VERSION=1.25.1
ARG MACOSX_SDK_PREFIX=0.0.1
ARG MACOSX_SDK_VERSION=10.15.4
ARG CCTOOLS_VERSION=949.0.1
ARG LD64_VERSION=530
ARG ARCH=x86_64

WORKDIR /root

COPY install.sh /root/install.sh
RUN /root/install.sh

FROM scratch

WORKDIR /work

ENV PATH=/opt/ldc/bin:/usr/bin
ENTRYPOINT ["ldc2"]

COPY --from=builder /rootfs /
