FROM alpine:latest

# 更新apk源并安装必要的包，包括中文字体、screen、nano、wget
RUN apk update && \
    apk add --no-cache screen && \
    apk add --no-cache nano && \
    apk add --no-cache wget && \
    apk add --no-cache ttf-dejavu && \
    apk add --no-cache bash && \
    apk add --no-cache ca-certificates && \
    rm -rf /var/cache/apk/*

# 设置中文语言环境
RUN echo "export LANG=zh_CN.UTF-8" >> /etc/profile && \
    echo "export LANGUAGE=zh_CN:zh" >> /etc/profile && \
    echo "export LC_ALL=zh_CN.UTF-8" >> /etc/profile

# 设置环境变量
ENV LANG zh_CN.UTF-8
ENV LC_ALL zh_CN.UTF-8

# 工作目录
WORKDIR /app

# 拷贝二进制和配置文件
COPY ./mp4decrypt /usr/bin/
COPY ./MP4Box /usr/bin/
COPY ./output/ /app/
COPY ./backup/ /app/backup/
COPY ./start.sh /app/

# 赋予执行权限
RUN chmod -R 755 /app && \
    chmod 755 /usr/bin/mp4decrypt  /usr/bin/MP4Box /app/start.sh && \
    ln -s /app/z_amdl/dl /usr/bin && \
    ln -s /app/s_amdl/sdl /usr/bin

EXPOSE 7681

# 启动脚本
CMD bash -c "/app/start.sh"
