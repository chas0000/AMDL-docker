#!/bin/sh
set -e

echo "[INFO] Starting wrapper manager..."

# ===============================
# 复制配置文件
# ===============================
mkdir -p /app/wrapper/config

if [ ! -f "/app/wrapper/config/wm_config.yaml" ]; then
    echo "[INFO] Copying default wm_config.yaml..."
    cp "/app/backup/wm_config.yaml" "/app/wrapper/config/wm_config.yaml"
fi

# 复制到工作目录
cp "/app/wrapper/config/wm_config.yaml" "/app/wrapper/config.yaml"

echo "[INFO] Configuration ready."
echo "[INFO] Starting wm_server..."

# 启动 wm_server
exec ./wm_server
