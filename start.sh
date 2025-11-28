#!/bin/sh
set -e

echo "[INFO] Starting application..."

# ===============================
# 复制配置文件
# ===============================
mkdir -p /app/config

for f in config.yaml sky_config.yaml; do
    if [ ! -f "/app/config/$f" ]; then
        cp "/app/backup/$f" "/app/config/$f"
    fi
    cp "/app/config/$f" "/app/$f"
done

# 启动 wm_server
cd /app/wrapper
./wm_server --config /app/config/manager.json &
cd /app

# ===============================
# 设置 tmux socket 目录
# ===============================
export TMUX_TMPDIR=/tmp/tmux
mkdir -p "$TMUX_TMPDIR"
chmod 700 "$TMUX_TMPDIR"

SESSION_NAME=mysession

# ===============================
# 强制杀掉旧 tmux server（确保 -f 生效）
# ===============================
tmux kill-server 2>/dev/null || true

# ===============================
# 启动 tmux session
# ===============================
TMUX_CONF="/app/config/.tmux.conf"

if [ -f "$TMUX_CONF" ]; then
    echo "[INFO] Creating tmux session $SESSION_NAME with custom config..."
    tmux -f "$TMUX_CONF" new-session -d -s "$SESSION_NAME" "bash"
else
    echo "[INFO] Creating tmux session $SESSION_NAME with default config..."
    tmux new-session -d -s "$SESSION_NAME" "bash"
fi

# ===============================
# 等待 session 就绪
# ===============================
while ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; do
    sleep 0.1
done

# 清理可能的嵌套 tmux 环境
unset TMUX

# ===============================
# 启动 ttyd 并 attach tmux session
# ===============================
TTYD_CMD="tmux attach -t $SESSION_NAME"

if [ -n "$TTYD_USER" ] && [ -n "$TTYD_PASS" ]; then
    echo "[INFO] Starting ttyd with auth..."
    exec ttyd -W env LANG=zh_CN.UTF-8 LC_ALL=zh_CN.UTF-8 -c "$TTYD_USER:$TTYD_PASS" $TTYD_CMD
else
    echo "[INFO] Starting ttyd without auth..."
    exec ttyd -W env LANG=zh_CN.UTF-8 LC_ALL=zh_CN.UTF-8 $TTYD_CMD
fi

# ===============================
# 等待并正确退出
# ===============================
wait -n
exit $?
