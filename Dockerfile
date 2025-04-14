ARG base_image=ubuntu:noble

# Base image, installs various commonly used tools
FROM $base_image AS base
RUN apt update \
    && apt install -y \
        build-essential \
        wget \
        git \
        curl \
        vim \
        ca-certificates \
        gnupg \
        pkg-config \
        libssl-dev

# Build WABT tools from source
FROM base AS wabt
WORKDIR /app
RUN apt install -y \
        cmake \
        software-properties-common \
        python3-pip \
    && git clone --recursive https://github.com/WebAssembly/wabt \
    && cd wabt \
    && git submodule update --init \
    && mkdir build \
    && cd build \
    && cmake .. \
    && cmake --build .

# Build final image
FROM base
ARG wasi_sdk=24
ARG dotnet_repo=24.04
ARG dotnet_version=8.0
ARG node_major=20
ARG wasm_tools=1.216.0

# Copy WABT tools
COPY --from=wabt /app/wabt/build/* /opt/wabt/bin/
RUN echo 'export PATH=$PATH:/opt/wabt/bin' >> ~/.bashrc

# Install wasmtime and wasmer
RUN curl https://wasmtime.dev/install.sh -sSf | bash
RUN curl https://get.wasmer.io -sSfL | bash

# Install Rust and wasm targets
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
ENV PATH=$PATH:/root/.cargo/bin
RUN rustup target add wasm32-wasip1 wasm32-unknown-unknown
RUN curl https://rustwasm.github.io/wasm-pack/installer/init.sh -sSf | sh

# Install cargo tools
RUN cargo install --locked cargo-component \
    && cargo install wac-cli \
    && cargo install --git https://github.com/bytecodealliance/wit-bindgen wit-bindgen-cli \
    && cargo install cargo-wasix

# Install wasi-sdk for ARM64 (corrected URL)
RUN cd /opt \
    && wget https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-$wasi_sdk/wasi-sdk-$wasi_sdk.0-arm64-linux.tar.gz \
    && tar xvf wasi-sdk-$wasi_sdk.0-arm64-linux.tar.gz \
    && rm wasi-sdk-$wasi_sdk.0-arm64-linux.tar.gz \
    && echo 'export PATH=$PATH:/opt/wasi-sdk-$wasi_sdk.0/bin' >> ~/.bashrc

# Install wasm-tools for ARM64
RUN cd /opt \
    && wget https://github.com/bytecodealliance/wasm-tools/releases/download/v$wasm_tools/wasm-tools-$wasm_tools-aarch64-linux.tar.gz \
    && tar xvf wasm-tools-$wasm_tools-aarch64-linux.tar.gz \
    && rm wasm-tools-$wasm_tools-aarch64-linux.tar.gz \
    && mv ./wasm-tools-$wasm_tools-aarch64-linux ./wasm-tools \
    && echo 'export PATH=$PATH:/opt/wasm-tools' >> ~/.bashrc

# Install .NET SDK for ARM64
RUN wget https://packages.microsoft.com/config/ubuntu/$dotnet_repo/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && rm packages-microsoft-prod.deb \
    && apt update \
    && apt install dotnet-sdk-$dotnet_version -y \
    && dotnet workload install wasm-tools wasm-experimental \
    && apt install libxml2

# Install just
RUN curl -sSf https://just.systems/install.sh | bash -s -- --to /opt/just \
    && echo 'export PATH=$PATH:/opt/just' >> ~/.bashrc

# Install Node.js for ARM64
RUN apt remove nodejs npm -y \
    && apt update \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$node_major.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
    && apt update \
    && apt install nodejs -y \
    && npm install --global http-server \
    && npm install --global @bytecodealliance/jco @bytecodealliance/componentize-js

# Install Emscripten SDK
WORKDIR /root
RUN git clone https://github.com/emscripten-core/emsdk.git \
    && cd emsdk \
    && ./emsdk install latest \
    && ./emsdk activate latest \
    && echo 'export PATH=$PATH:/root/emsdk:/root/emsdk/upstream/emscripten' >> ~/.bashrc \
    && echo 'export EMSDK=/root/emsdk' >> ~/.bashrc \
    && echo 'export EMSDK_NODE=/root/emsdk/node/16.20.0_64bit/bin/node' >> ~/.bashrc

ENV CCWASM="/opt/wasi-sdk-$wasi_sdk.0-arm64-linux/bin/clang --sysroot=/opt/wasi-sdk-$wasi_sdk.0-arm64-linux/share/wasi-sysroot"
WORKDIR /root

#docker build -t wasm-dev-image .
#docker run -it wasm-dev-image bash