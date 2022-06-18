FROM golang:1.17-bullseye

RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y tzdata gcc g++ make git curl wget cmake libssl-dev libssh2-1-dev && \
    apt clean

# build libgit2 1.3.x
RUN mkdir /tmp/libgit2 && \
    cd /tmp/libgit2 && \
    wget -O - https://github.com/libgit2/libgit2/archive/refs/tags/v1.3.1.tar.gz | tar -xz && \
    cd libgit2-* && \
    mkdir build && cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr -DBUILD_CLAR=OFF -DBUILD_EXAMPLES=OFF .. && \
    make -j install && \
    cd / && rm -fr /tmp/libgit2

# goproxy if needed
RUN go env -w GO111MODULE=on

# go packages needed for devel
RUN go install -v github.com/vektra/mockery/v2@v2.12.3 && \
    go install -v golang.org/x/tools/gopls@latest && \
    go install -v honnef.co/go/tools/cmd/staticcheck@latest && \
    curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin v1.43.0 && \
    rm -fr ${HOME}/.cache/*

# for config-ui, nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash
ENV NVM_DIR $HOME/.nvm

RUN echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" ' >> ~/.bashrc && \
    echo '[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion" ' >> ~/.bashrc

RUN . $HOME/.bashrc && \
    nvm install 16