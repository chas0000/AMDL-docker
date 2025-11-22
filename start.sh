#!/bin/sh
set -e

echo "[INFO] Starting application..."

# ===============================
#  检查并复制配置文件（无覆盖逻辑错误）
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
cd /app/wrapper
./wm_server --config /app/config/manager.json &
cd /app
# -----------------------------
#  设置 tmux socket 目录
# -----------------------------
export TMUX_TMPDIR=/tmp/tmux
mkdir -p "$TMUX_TMPDIR"
chmod 700 "$TMUX_TMPDIR"

SESSION_NAME=mysession

# -----------------------------
#  启动 tmux session 后台运行 Python（只启动一次）
# -----------------------------
if ! tmux has-session -t $SESSION_NAME 2>/dev/null; then
    echo "[INFO] Creating tmux session $SESSION_NAME..."
    tmux new-session -d -s $SESSION_NAME "bash"
fi

# -----------------------------
#  等待 session 就绪
# -----------------------------
sleep 2

# -----------------------------
#  清理可能的嵌套 tmux 环境
# -----------------------------
unset TMUX

# -----------------------------
#  启动 ttyd 并 attach tmux session
# -----------------------------
TTYD_CMD="tmux attach -t $SESSION_NAME"

if [ -n "$TTYD_USER" ] && [ -n "$TTYD_PASS" ]; then
    echo "[INFO] Starting ttyd with auth..."
    exec ttyd -W env LANG=zh_CN.UTF-8 LC_ALL=zh_CN.UTF-8 -c "$TTYD_USER:$TTYD_PASS" $TTYD_CMD
else
    echo "[INFO] Starting ttyd without auth..."
    exec ttyd -W env LANG=zh_CN.UTF-8 LC_ALL=zh_CN.UTF-8 $TTYD_CMD
fi
    


echo "[INFO] All services started."

# ===============================
# 3. 等待并正确退出
# ===============================
wait -n     # 任一进程退出就退出容器
exit $?
