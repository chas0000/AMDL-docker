# syntax=docker/dockerfile:1.4

FROM alpine:latest
ARG TARGETARCH

# 安装基础依赖与中文支持
RUN apk update && \
    apk add --no-cache \
      bash screen nano wget ca-certificates ttf-dejavu && \
    rm -rf /var/cache/apk/*

# 设置中文环境
RUN echo "export LANG=zh_CN.UTF-8" >> /etc/profile && \
    echo "export LANGUAGE=zh_CN:zh" >> /etc/profile && \
    echo "export LC_ALL=zh_CN.UTF-8" >> /etc/profile
ENV LANG zh_CN.UTF-8
ENV LC_ALL zh_CN.UTF-8

WORKDIR /app

# 复制通用文件
COPY ./mp4decrypt /usr/bin/
COPY ./MP4Box /usr/bin/
COPY ./output/ /app/
COPY ./backup/ /app/backup/
COPY ./start.sh /app/

# 根据架构选择二进制（dl, sdl, ttyd）
RUN if [ "$TARGETARCH" = "amd64" ]; then \
        echo "==> using amd64 binaries"; \
        mv /app/dl-amd64 /app/dl && \
        mv /app/sdl-amd64 /app/sdl && \
        mv /app/ttyd-amd64 /usr/bin/ttyd; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
        echo "==> using arm64 binaries"; \
        mv /app/dl-arm64 /app/dl && \
        mv /app/sdl-arm64 /app/sdl && \
        mv /app/ttyd-arm64 /usr/bin/ttyd; \
    else \
        echo "⚠ 未知架构 $TARGETARCH, 默认使用 amd64"; \
        mv /app/dl-amd64 /app/dl && \
        mv /app/sdl-amd64 /app/sdl && \
        mv /app/ttyd-amd64 /usr/bin/ttyd; \
    fi && \
    chmod -R 755 /app && \
    chmod 755 /usr/bin/mp4decrypt /usr/bin/MP4Box /usr/bin/ttyd /app/start.sh && \
    ln -sf /app/dl /usr/bin/dl && \
    ln -sf /app/sdl /usr/bin/sdl

EXPOSE 7681

# 启动脚本
CMD bash -c "/app/start.sh && ttyd -W screen -xR mysession bash"
