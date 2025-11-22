# =========================
# Stage 1: Build all binaries
# =========================
FROM golang:1.24-bullseye AS builder

# 安装构建依赖
RUN apt-get update && apt-get install -y \
    git wget tar curl  build-essential pkg-config g++ cmake yasm zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
RUN mkdir -p /build/amdl && mkdir -p /build/backup && mkdir -p /build/wrapper

# -------------------------
# 1. 构建 apple-music-downloader
# -------------------------
RUN git clone https://github.com/zhaarey/apple-music-downloader.git \
    && cd apple-music-downloader \
    && CGO_ENABLED=0 GOOS=linux  go build -a -o dl main.go \
    && cp dl /build/amdl/dl \
    && cp config.yaml /build/backup/config.yaml

# -------------------------
# 2. 下载 sky8282/apple-music-downloader
# -------------------------
WORKDIR /build
RUN mkdir -p ./sky
RUN git clone --depth=1 https://github.com/sky8282/apple-music-downloader.git ./sky/apple-music-downloader
WORKDIR /build/sky/apple-music-downloader
RUN sed -i 's|config.yaml|sky_config.yaml|g' ./main.go \
    && sed -i 's|config.yaml|sky_config.yaml|g' ./internal/core/state.go    
RUN go mod tidy
RUN CGO_ENABLED=0 GOOS=linux  go build -a -o sdl main.go \
    && cp sdl /build/amdl/sdl \
    && cp config.yaml /build/backup/sky_config.yaml     

# -------------------------
# 3. 构建 wrapper-manager-v1
# -------------------------
RUN git clone https://github.com/sky8282/wrapper-manager-v1.git \
    && cd wrapper-manager-v1 \
    && go mod init wrapper-manager \
    && go mod tidy \
    && CGO_ENABLED=0 GOOS=linux  go build -a -o wm_server main.go \
    && cp wm_server /build/wrapper/wm_server \
    && cp index.html /build/wrapper/index.html

# -------------------------
# 4. 构建 shell_web
# -------------------------
# 假设 shell_web.go 已经在上下文里 COPY 进 /build
COPY shell_web.go /build/shell_web.go
RUN mkdir /build/shell_web \
    && cp /build/shell_web.go /build/shell_web/shell_web.go \
    && cd /build/shell_web \
    && go mod init shell_web \
    && go mod tidy \
    && go build -a -o shell_web shell_web.go


# =========================
# Stage 2: Create final image
# =========================
FROM ubuntu:22.04

WORKDIR /app
COPY ./start.sh /app2/
RUN set -eux; \
    apt-get update && apt-get install -y --no-install-recommends \
        g++ \
        make \
        cmake \
        zlib1g-dev \
        coreutils \
        git \
        wget \
        curl \
        ca-certificates \
        ffmpeg \
        ttyd \
        tmux \
        && rm -rf /var/lib/apt/lists/*; \
    \
    # Build and install GPAC
    git clone --depth=1 https://github.com/gpac/gpac.git ./build/gpac || exit 1; \
    cd ./build/gpac; \
    ./configure; \
    make -j$(nproc); \
    make install; \
    MP4BOX_PATH=$(command -v MP4Box); \
    if [ -n "$MP4BOX_PATH" ]; then ln -sf "$MP4BOX_PATH" "$(dirname "$MP4BOX_PATH")/mp4box"; fi; \
    cd /app; \
    \
    # Build and install Bento4
    git clone --depth=1 https://github.com/axiomatic-systems/Bento4.git ./build/Bento4 || exit 1; \
    mkdir -p ./build/Bento4/cmakebuild; \
    cd ./build/Bento4/cmakebuild; \
    cmake -DCMAKE_BUILD_TYPE=Release ..; \
    make -j$(nproc); \
    make install; \
    cd /app; \
    \
    # Clean up
    rm -rf ./build; 
    
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
COPY --from=builder /build/amdl/ /app/
COPY --from=builder /build/backup /app/backup/
COPY --from=builder /build/wrapper/ /app/wrapper/
COPY --from=builder /build/shell_web/shell_web /app/shell_web

# 设置可执行权限
RUN chmod +x /app/dl /app/sdl  /app/shell_web /app/wrapper/wm_server /app2/start.sh \
     && ln -sf /app/dl /usr/local/bin/dl \
     && ln -sf /app/sdl /usr/local/bin/sdl

# 设置默认启动命令（可改为你的 start.sh）
CMD ["/bin/bash","/app2/start.sh"]
