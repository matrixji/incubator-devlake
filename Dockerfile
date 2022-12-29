# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#
# Apache DevLake is an effort undergoing incubation at The Apache Software
# Foundation (ASF), sponsored by the Apache Incubator PMC.
#
# Incubation is required of all newly accepted projects until a further
# review indicates that the infrastructure, communications, and decision
# making process have stabilized in a manner consistent with other
# successful ASF projects.
#
# While incubation status is not necessarily a reflection of the
# completeness or stability of the code, it does indicate that the project
# has yet to be fully endorsed by the ASF.


FROM --platform=$BUILDPLATFORM golang:1.19-bullseye as builder

# docker build --build-arg HTTPS_PROXY=http://localhost:4780 -t mericodev/lake .
ARG HTTP_PROXY=
ARG HTTPS_PROXY=
ARG TAG=
ARG SHA=

RUN apt-get update
RUN apt-get install -y \
    gcc binutils libfindbin-libs-perl \
    cmake

RUN if [ "$(arch)" != "aarch64" ] ; then \
        apt-get install -y gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu ; \
    fi
RUN if [ "$(arch)" != "x86_64" ] ; then \
        apt-get install -y gcc-x86-64-linux-gnu binutils-x86-64-linux-gnu ; \
    fi

RUN go install github.com/vektra/mockery/v2@v2.12.3
RUN go install github.com/swaggo/swag/cmd/swag@v1.8.4

ENV DEPS_DIR=/usr/local/lake-deps
ARG TARGETPLATFORM

RUN mkdir -p ${DEPS_DIR} && cd ${DEPS_DIR} && \
    wget https://zlib.net/zlib-1.2.13.tar.gz -O - | tar -xz && \
    cd zlib-1.2.13 && \
    mkdir build && cd build && \
    if [ "$TARGETPLATFORM" = "linux/arm64" ] ; then \
        cmake .. -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc -DCMAKE_INSTALL_PREFIX=${DEPS_DIR}/rootfs ; \
    elif [ "$TARGETPLATFORM" = "linux/amd64" ] ; then \
        cmake .. -DCMAKE_C_COMPILER=x86_64-linux-gnu-gcc -DCMAKE_INSTALL_PREFIX=${DEPS_DIR}/rootfs ; \
    fi && \
    make -j install && \
    cd / && rm -fr ${DEPS_DIR}/zlib-*

RUN mkdir -p ${DEPS_DIR} && cd ${DEPS_DIR} && \
    wget https://www.openssl.org/source/openssl-1.1.1s.tar.gz -O - | tar -xz && \
    cd openssl-1.1.1s && \
    if [ "$TARGETPLATFORM" = "linux/arm64" ] ; then \
        ./Configure linux-aarch64 --cross-compile-prefix=aarch64-linux-gnu- --prefix=${DEPS_DIR}/rootfs ; \
    elif [ "$TARGETPLATFORM" = "linux/amd64" ] ; then \
        ./Configure linux-x86_64 --cross-compile-prefix=x86_64-linux-gnu- --prefix=${DEPS_DIR}/rootfs ; \
    fi && \
    make -j && make install_sw && \
    cd / && rm -fr ${DEPS_DIR}/openssl-*

RUN mkdir -p ${DEPS_DIR} && cd ${DEPS_DIR} && \
    wget https://github.com/libssh2/libssh2/releases/download/libssh2-1.10.0/libssh2-1.10.0.tar.gz -O - | tar -xz && \
    cd libssh2-1.10.0 && \
    mkdir build && cd build && \
    if [ "$TARGETPLATFORM" = "linux/arm64" ] ; then \
        cmake  .. -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc \
            -DBUILD_SHARED_LIBS=ON -DCMAKE_INSTALL_PREFIX=${DEPS_DIR}/rootfs \
            -DCRYPTO_BACKEND=OpenSSL -DENABLE_ZLIB_COMPRESSION=ON -DENABLE_CRYPT_NONE=ON -DENABLE_MAC_NONE=ON ; \
    elif [ "$TARGETPLATFORM" = "linux/amd64" ] ; then \
        cmake  .. -DCMAKE_C_COMPILER=x86_64-linux-gnu-gcc \
            -DBUILD_SHARED_LIBS=ON -DCMAKE_INSTALL_PREFIX=${DEPS_DIR}/rootfs \
            -DCRYPTO_BACKEND=OpenSSL -DENABLE_ZLIB_COMPRESSION=ON -DENABLE_CRYPT_NONE=ON -DENABLE_MAC_NONE=ON ; \
    fi && \
    make -j install && \
    cd / && rm -fr ${DEPS_DIR}/libssh2-*

RUN mkdir -p ${DEPS_DIR} && cd ${DEPS_DIR} && \
    wget https://github.com/libgit2/libgit2/archive/refs/tags/v1.3.2.tar.gz -O - | tar -xz && \
    cd libgit2-1.3.2 && \
    mkdir build && cd build && \
    if [ "$TARGETPLATFORM" = "linux/arm64" ] ; then \
        cmake .. -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc -DBUILD_SHARED_LIBS=ON -DCMAKE_INSTALL_PREFIX=${DEPS_DIR}/rootfs ; \
    elif [ "$TARGETPLATFORM" = "linux/amd64" ] ; then \
        cmake .. -DCMAKE_C_COMPILER=x86_64-linux-gnu-gcc -DBUILD_SHARED_LIBS=ON -DCMAKE_INSTALL_PREFIX=${DEPS_DIR}/rootfs ; \
    fi && \
    make -j install && \
    cd / && rm -fr ${DEPS_DIR}/libgit2-*

WORKDIR /app
COPY . /app
ENV GOBIN=/app/bin

RUN --mount=type=cache,target=/root/.cache/go-build \
    if [ "$TARGETPLATFORM" = "linux/arm64" ] ; then \
        CC=aarch64-linux-gnu-gcc GOARCH=arm64 CGO_ENABLED=1 \
        PKG_CONFIG_PATH=${DEPS_DIR}/rootfs/lib/pkgconfig:${DEPS_DIR}/rootfs/share/pkgconfig \
        make all ; \
    else \
        CC=x86_64-linux-gnu-gcc GOARCH=amd64 CGO_ENABLED=1 \
        PKG_CONFIG_PATH=${DEPS_DIR}/rootfs/lib/pkgconfig:${DEPS_DIR}/rootfs/share/pkgconfig \
        make all ; \
    fi



FROM debian:bullseye

ENV PYTHONUNBUFFERED=1

RUN apt-get update && \
    apt-get install -y python3-dev python3-pip tar curl && \
    apt-get clean && \
    python3 -m pip install --no-cache --upgrade pip setuptools && \
    python3 -m pip install --no-cache dbt-mysql dbt-postgres


EXPOSE 8080

WORKDIR /app

# libraries
RUN mkdir -p /app/libs
ENV LD_LIBRARY_PATH=/app/libs
COPY --from=builder /usr/local/lake-deps/rootfs/lib/lib*so* /app/libs

COPY --from=builder /app/bin /app/bin
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=builder /app/requirements.txt /app/requirements.txt
COPY --from=builder /app/config/tap /app/config/tap

# Setup Python
RUN python3 -m pip install --no-cache --upgrade pip -r requirements.txt

ENV PATH="/app/bin:${PATH}"

CMD ["lake"]

