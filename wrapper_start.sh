#!/bin/sh
set -e

echo "[INFO] Starting wrapper manager..."

# ===============================
# 复制配置文件
# ===============================
mkdir -p /app/wrapper/config
mkdir -p /app/config

for f in wm_config.yaml; do
    if [ ! -f "/app/config/$f" ]; then
        cp "/app/backup/$f" "/app/config/$f"
    fi
    cp "/app/config/$f" "/app/wrapper/config.yaml"
done

# 处理 manager.json (由wm_server自动生成)
# 如果 /app/config/ 没有 manager.json 但 /app/wrapper 有（之前运行生成的），则从 wrapper 复制到 config
if [ ! -f "/app/config/manager.json" ] && [ -f "/app/wrapper/manager.json" ]; then
    echo "[INFO] Copying existing manager.json from wrapper to config..."
    cp "/app/wrapper/manager.json" "/app/config/manager.json"
fi

# 如果 /app/config/ 有 manager.json，复制到 /app/wrapper
if [ -f "/app/config/manager.json" ]; then
    echo "[INFO] Copying manager.json from config to wrapper..."
    cp "/app/config/manager.json" "/app/wrapper/manager.json"
fi

echo "[INFO] Configuration ready."
echo "[INFO] Starting wm_server..."

# 启动 wm_server
exec ./wm_server
