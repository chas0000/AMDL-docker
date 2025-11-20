#!/bin/sh
set -e

echo "[INFO] Starting application..."

# ===============================
# 1. 检查并复制配置文件（无覆盖逻辑错误）
# ===============================

# 1. 检查 /app/amdl/config.yaml 是否存在
if [ ! -f /app/config/config.yaml ]; then
    cp /app/backup/config.yaml /app/config.yaml
    cp /app/backup/config.yaml /app/config/config.yaml
else
    cp /app/config/config.yaml /app/config.yaml   
fi
if [ ! -f /app/config/sky_config.yaml ]; then
    cp /app/backup/sky_config.yaml /app/sky_config.yaml
    cp /app/backup/sky_config.yaml /app/config/sky_config.yaml
else
    cp /app/config/sky_config.yaml /app/sky_config.yaml  
fi

# ===============================
# 2. 启动后台服务
# ===============================
cd /app/wrapper
./wm_server &

cd /app
./shell_web &

echo "[INFO] All services started."

# ===============================
# 3. 等待并正确退出
# ===============================
wait -n     # 任一进程退出就退出容器
exit $?
