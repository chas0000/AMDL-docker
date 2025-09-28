#!/bin/bash
set -e
echo "尝试启动"
# 1. 检查 /app/amdl/config.yaml 是否存在
if [ ! -f /app/config/z_amdl/config.yaml ]; then
    cp /app/backup/z_amdl/config.yaml /app/z_amdl/config.yaml
    cp /app/backup/z_amdl/config.yaml /app/config.yaml
else
    cp /app/config/z_amdl/config.yaml /app/z_amdl/config.yaml   
fi
if [ ! -f /app/config/s_amdl/config.yaml ]; then
    cp /app/backup/s_amdl/config.yaml /app/s_amdl/config.yaml
else
    cp /app/config/s_amdl/config.yaml /app/s_amdl/config.yaml     
fi

export TERM=xterm-256color
export LANG=zh_CN.UTF-8
# 后台运行 ttyd
ttyd -W  screen -xR mysession bash &
#ttyd -W  bash &
#ttyd -W  screen -xR mysession &
#ttyd -W tmux new -A -s mysession &
exit 0
