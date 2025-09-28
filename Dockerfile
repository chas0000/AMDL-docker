FROM alpine:latest

# 安装必要的包，包括glibc支持语言环境、screen、nano、wget和中文字体
RUN apk update && \
    apk add --no-cache \
    glibc-i18n \
    screen \
    nano \
    wget \
    ttf-wqy-zenhei

# 生成中文语言环境
RUN echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen

# 设置默认语言环境为zh_CN.UTF-8
ENV LANG zh_CN.UTF-8
ENV LC_ALL zh_CN.UTF-8

# 清理缓存
RUN rm -rf /var/cache/apk/*


WORKDIR /app
# 拷贝二进制和配置文件

COPY ./mp4decrypt /usr/bin/
COPY ./MP4box-output/MP4Box /usr/bin/
COPY ./amdl-output/ttyd /usr/bin/
COPY ./amdl-output/z_amdl/dl /app/z_amdl/
COPY ./amdl-output/s_amdl/dl /app/s_amdl/
COPY ./backup /app/
COPY ./start.sh /app/
RUN chmod -R 755 /app &&  chmod 755 /usr/bin/mp4decrypt /usr/bin/ttyd /usr/bin/MP4Box /app/start.sh && ln -s /app/z_amdl/dl /usr/bin && && ln -s /app/s_amdl/sdl /usr/bin
EXPOSE 7681 

CMD bash -c "/app/start.sh "
