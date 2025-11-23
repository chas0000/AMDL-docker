FROM ubuntu:22.04

# 设置工作目录
WORKDIR /app

# 复制文件
COPY ./start.sh /app2/
COPY ./output /app/
COPY ./backup /app/

# 安装基础依赖
RUN set -eux; \
    apt-get update && apt-get install -y --no-install-recommends \
        nano \
        wget \
        curl \
        ca-certificates \
        git \
        ffmpeg \
        tmux \
        g++ \
        make \
        cmake \
        zlib1g-dev \
        coreutils \
    && rm -rf /var/lib/apt/lists/*

# 下载 wrapper 根据架构
RUN set -eux; \
    ARCH=$(dpkg --print-architecture); \
    echo "架构为: $ARCH"; \
    case "$ARCH" in \
        amd64) WRAPPER_URL="https://github.com/zhaarey/wrapper/releases/download/linux.V2/wrapper.x86_64.tar.gz" ;; \
        arm64) WRAPPER_URL="https://github.com/zhaarey/wrapper/releases/download/arm64/wrapper.arm64.tar.gz" ;; \
        *) echo "Unsupported architecture: $ARCH" && exit 1 ;; \
    esac; \
    wget "$WRAPPER_URL" -O /tmp/wrapper.tar.gz; \
    mkdir -p /app/wrapper; \
    tar -xzf /tmp/wrapper.tar.gz -C /app/wrapper; \
    rm /tmp/wrapper.tar.gz

# 构建 GPAC 和 Bento4
RUN set -eux; \
    mkdir -p /app/build; \
    \
    # Build GPAC
    git clone --depth=1 https://github.com/gpac/gpac.git /app/build/gpac; \
    cd /app/build/gpac; \
    ./configure; \
    make -j$(nproc); \
    mv ./bin/gcc/MP4Box /usr/local/bin/MP4Box; \
    \
    # Build Bento4
    git clone --depth=1 https://github.com/axiomatic-systems/Bento4.git /app/build/Bento4; \
    mkdir -p /app/build/Bento4/cmakebuild; \
    cd /app/build/Bento4/cmakebuild; \
    cmake -DCMAKE_BUILD_TYPE=Release ..; \
    make -j$(nproc); \
    mv ./mp4decrypt /usr/local/bin/mp4decrypt; \
    \
    # 清理
    rm -rf /app/build; \
    apt-get purge -y g++ make cmake git wget curl; \
    apt-get autoremove -y

# 根据架构选择二进制文件
RUN set -eux; \
    ARCH=$(dpkg --print-architecture); \
    ls /app
    case "$ARCH" in \
        amd64) \
            mv /app/dl-amd64 /app/dl; \
            mv /app/sdl-amd64 /app/sdl; \
            mv /app/wm_server-amd64 /app/wrapper/wm_server; \
            mv /app/ttyd-amd64 /usr/local/bin/ttyd ;; \
        arm64) \
            mv /app/dl-arm64 /app/dl; \
            mv /app/sdl-arm64 /app/sdl; \
            mv /app/wm_server-arm64 /app/wrapper/wm_server; \
            mv /app/ttyd-arm64 /usr/local/bin/ttyd ;; \
        *) echo "❌ 不支持的架构: $TARGETARCH" && exit 1 ;; \
    esac; \
    rm -rf /app/output; \
    chmod 755 /app/wrapper/wm_server /usr/local/bin/ttyd /app/dl /app/sdl; \
    ln -sf /app/dl /usr/local/bin/dl; \
    ln -sf /app/sdl /usr/local/bin/sdl

# 环境变量
ENV TTYD_USER=""
ENV TTYD_PASS=""

# 默认启动命令
CMD ["/bin/bash","/app2/start.sh"]
