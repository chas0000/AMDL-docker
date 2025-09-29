#!/bin/bash
set -e
echo "尝试启动"
# 1. 检查 /app/amdl/config.yaml 是否存在
if [ ! -f /app/config/config.yaml ]; then
    cp /app/backup/config.yaml /app/config.yaml
else
    cp /app/config/config.yaml /app/config.yaml   
fi
if [ ! -f /app/config/sky_config.yaml ]; then
    cp /app/backup/sky_config.yaml /app/sky_config.yaml
else
    cp /app/config/sky_config.yaml /app/sky_config.yaml  
fi

export TERM=xterm-256color
export LANG=zh_CN.UTF-8
# 后台运行 ttyd
#ttyd -W  screen -xR mysession bash &
#ttyd -W  bash &
#ttyd -W  screen -xR mysession &
#ttyd -W tmux new -A -s mysession &
exit 0
