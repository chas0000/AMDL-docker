
FROM ubuntu:22.04

WORKDIR /app
COPY ./start.sh /app2/
COPY ./output /app/
COPY ./backup /app/
RUN set -eux; \
    apt-get update && apt-get install -y --no-install-recommends \
        nano\
        ffmpeg \
        tmux \
        && rm -rf /var/lib/apt/lists/*; \
    \
RUN set -eux; \
    ARCH=$(dpkg --print-architecture); \
    if [ "$ARCH" = "amd64" ]; then \
        WRAPPER_URL="https://github.com/zhaarey/wrapper/releases/download/linux.V2/wrapper.x86_64.tar.gz"; \
    elif [ "$ARCH" = "arm64" ]; then \
        WRAPPER_URL="https://github.com/zhaarey/wrapper/releases/download/arm64/wrapper.arm64.tar.gz"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi; \
    wget "$WRAPPER_URL" -O /tmp/wrapper.tar.gz; \
    mkdir -p /app/wrapper; \
    tar -xzf /tmp/wrapper.tar.gz -C /app/wrapper; \
    apt-get purge -y g++ make cmake git wget curl; \
    apt-get autoremove -y; \
    rm /tmp/wrapper.tar.gz
# 复制编译好的二进制和文件
RUN set -eux; \
    apk add --no-cache  g++ make cmake zlib-dev coreutils; \
    \
    # Build and install GPAC
    \
    git clone --depth=1 https://github.com/gpac/gpac.git ./build/gpac || exit 1; \
    cd ./build/gpac; \
    ./configure; \
    make -j$(nproc); \
    mv ./bin/gcc/MP4Box /usr/local/bin/MP4Box; \
    cd /app; \
    \
    # Build and install Bento4
    \
    git clone --depth=1 https://github.com/axiomatic-systems/Bento4.git ./build/Bento4 || exit 1; \
    mkdir -p ./build/Bento4/cmakebuild; \
    cd ./build/Bento4/cmakebuild; \
    cmake -DCMAKE_BUILD_TYPE=Release ..; \
    make -j$(nproc); \
    mv ./mp4decrypt /usr/local/bin/mp4decrypt; \
    cd /app; \
    \
    # Clean up
    \
    rm -rf ./build; \
    apk del git g++ make cmake zlib-dev coreutils;
# 根据架构选择二进制（dl, sdl, ttyd）
RUN if [ "$TARGETARCH" = "amd64" ]; then \
        echo "==> using amd64 binaries"; \
        mv /app/dl-amd64 /app/dl && \
        mv /app/sdl-amd64 /app/sdl && \
        mv /app/wm_server-amd64 /app/wrapper/wm_server && \
        mv /app/MP4Box-amd64 /usr/local/bin/MP4Box &&\
        mv /app/mp4decrypt-amd64 /usr/local/bin/mp4decrypt &&\
        mv /app/ttyd-amd64 /usr/local/bin/ttyd &&\
        rm /app/output && \
        chmod 755 /app/wrapper/wm_server /usr/local/bin/mp4decrypt /usr/local/bin/MP4Box /usr/local/bin/ttyd /app/dl /app/sdl &&\
        ln -sf /app/dl /usr/local/bin/dl &&\
        ln -sf /app/sdl /usr/local/bin/sdl; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
        echo "==> using arm64 binaries"; \
        mv /app/dl-arm64 /app/dl && \
        mv /app/sdl-arm64 /app/sdl && \
        mv /app/wm_server-arm64 /app/wrapper/wm_server && \
        mv /app/MP4Box-arm64 /usr/local/bin/MP4Box &&\
        mv /app/mp4decrypt-arm64 /usr/local/bin/mp4decrypt &&\
        mv /app/ttyd-arm64 /usr/local/bin/ttyd &&\
        rm /app/output && \
        chmod 755 /app/wrapper/wm_server /usr/local/bin/mp4decrypt /usr/local/bin/MP4Box /usr/local/bin/ttyd /app/dl /app/sdl &&\
        ln -sf /app/dl /usr/local/bin/dl &&\
        ln -sf /app/sdl /usr/local/bin/sdl; \
    else \
        echo "❌ 不支持的架构: $TARGETARCH"; exit 1; \
    fi 


ENV TTYD_USER=""
ENV TTYD_PASS=""

# 设置默认启动命令（可改为你的 start.sh）
CMD ["/bin/bash","/app2/start.sh"]
