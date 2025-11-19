#!/bin/sh
set -e

echo "[INFO] Starting application..."

# ===============================
# 1. 检查并复制配置文件（无覆盖逻辑错误）
# ===============================

copy_if_missing() {
    src="$1"
    dest="$2"
    if [ ! -f "$dest" ]; then
        echo "[INFO] 初始化配置: $dest"
        cp "$src" "$dest"
    fi
}

# 统一确保 config 目录存在
mkdir -p /app/config

# 配置文件：amdl 原版
copy_if_missing /app/backup/config.yaml /app/config/config.yaml
copy_if_missing /app/backup/config.yaml /app/config.yaml

# 配置文件：sky 版本
copy_if_missing /app/backup/sky_config.yaml /app/config/sky_config.yaml
copy_if_missing /app/backup/sky_config.yaml /app/sky_config.yaml

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
