#!/bin/bash
set -e

# 1. 检查 /app/amdl/config.yaml 是否存在
if [ ! -f /app/config/z_amdl/config.yaml ]; then
    cp /app/backup/z_amdl/config.yaml /app/z_amdl/
else
    cp /app/config/z_amdl/config.yaml /app/z_amdl/config.yaml   
fi
if [ ! -f /app/config/s_amdl/config.yaml ]; then
    cp /app/backup/s_amdl/config.yaml /app/s_amdl/
else
    cp /app/config/s_amdl/config.yaml /app/s_amdl/config.yaml     
fi


# 2. 检查 /app/rootfs/data 是否为空
if [ ! -d /app/rootfs/data ] || [ -z "$(ls -A /app/rootfs/data 2>/dev/null)" ]; then
    echo "/app/rootfs/data 是空的，拷贝数据目录"
    shopt -s dotglob  # 启用 dotglob 选项以包含隐藏文件
    cp -r /backup/rootfs/. /app/rootfs/
    ls /app/rootfs/data
else
    echo "/app/rootfs/data 不为空，跳过拷贝"
fi
export TERM=xterm-256color
export LANG=zh_CN.UTF-8
# 后台运行 ttyd
ttyd -W  screen -xR mysession bash &
#ttyd -W  bash &
#ttyd -W  screen -xR mysession &
#ttyd -W tmux new -A -s mysession &
exit 0
