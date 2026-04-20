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

cd /app
./sdl --server --port 3000 &
cd /app


# ===============================
# 设置 tmux socket 目录
# ===============================
# 不使用自定义TMUX_TMPDIR，让tmux使用默认路径 /tmp/tmux-<uid>/
# 但需要确保 /tmp 目录权限正确
SESSION_NAME=amdl

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
    tmux -f "$TMUX_CONF" new-session -d -s "$SESSION_NAME" -c /app "bash"
else
    echo "[INFO] Creating tmux session $SESSION_NAME with default config..."
    tmux new-session -d -s "$SESSION_NAME" -c /app "bash"
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
# 配置并启动 SSH 服务
# ===============================
echo "[INFO] Configuring SSH service..."

# 设置SSH用户密码（从环境变量获取）
if [ -n "$SSH_USER" ] && [ -n "$SSH_PASSWORD" ]; then
    # 如果指定了非root用户，则创建该用户
    if [ "$SSH_USER" != "root" ]; then
        if ! id "$SSH_USER" &>/dev/null; then
            useradd -m -s /usr/local/bin/tmux-shell "$SSH_USER"
        fi
        echo "${SSH_USER}:${SSH_PASSWORD}" | chpasswd
        echo "[INFO] SSH user '$SSH_USER' created (non-root)"
    else
        # 如果使用root用户，直接设置密码
        echo "root:${SSH_PASSWORD}" | chpasswd
        echo "[INFO] SSH root login enabled"
    fi
else
    # 默认使用root用户，密码为password
    echo 'root:password' | chpasswd
    echo "[INFO] Using default root login (password: password)"
fi

# 配置SSH允许密码认证和root登录
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/PermitRootLogin no/PermitRootLogin yes/' /etc/ssh/sshd_config


# 配置SSH端口
if [ -n "$SSH_PORT" ] && [ "$SSH_PORT" != "22" ]; then
    # 如果指定了非默认端口，修改sshd_config
    if grep -q "^#Port 22" /etc/ssh/sshd_config; then
        # 如果有注释的Port行，取消注释并修改
        sed -i "s/^#Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config
    elif grep -q "^Port " /etc/ssh/sshd_config; then
        # 如果已有Port配置，直接替换
        sed -i "s/^Port .*/Port $SSH_PORT/" /etc/ssh/sshd_config
    else
        # 如果没有Port配置，在文件开头添加
        sed -i "1i Port $SSH_PORT" /etc/ssh/sshd_config
    fi
    echo "[INFO] SSH port set to $SSH_PORT"
else
    echo "[INFO] Using default SSH port 22"
fi

# 创建SSH登录脚本，直接attach到tmux session（仅用于非root用户）
cat > /usr/local/bin/tmux-shell << 'EOF'
#!/bin/bash

# 检查是否为交互式shell（有终端）
# SFTP/SCP等非交互式连接不会有tty
if [ -t 0 ]; then
    # 交互式shell，进入tmux
    
    # 如果已经在tmux会话中，则直接启动bash
    if [ -n "$TMUX" ]; then
        exec bash
    fi

    # 否则尝试attach到amdl会话，如果不存在则创建
    SESSION_NAME="amdl"
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        exec tmux attach -t "$SESSION_NAME"
    else
        exec tmux new-session -s "$SESSION_NAME"
    fi
else
    # 非交互式shell（SFTP/SCP等），直接启动bash
    exec bash
fi
EOF

chmod +x /usr/local/bin/tmux-shell

# 将tmux-shell设置为默认shell（针对特定用户）
if id "$SSH_USER" &>/dev/null && [ "$SSH_USER" != "root" ]; then
    chsh -s /usr/local/bin/tmux-shell "$SSH_USER" 2>/dev/null || true
    echo "[INFO] Set shell for user '$SSH_USER' to tmux-shell"
elif [ "$SSH_USER" = "root" ]; then
    # 如果是root用户，修改家目录为/app，并配置tmux auto-attach
    
    # 修改root的家目录为/app
    sed -i 's|^root:x:0:0:root:/root:|root:x:0:0:root:/app:|' /etc/passwd
    
    # 在sshd_config末尾添加ForceCommand配置，强制root用户使用tmux-shell
    echo '' >> /etc/ssh/sshd_config
    echo '# Force root user to use tmux-shell' >> /etc/ssh/sshd_config
    echo 'Match User root' >> /etc/ssh/sshd_config
    echo '    ForceCommand /usr/local/bin/tmux-shell' >> /etc/ssh/sshd_config
    
    echo "[INFO] Set root home to /app and configured ForceCommand for tmux"
fi

# 启动SSH服务
echo "[INFO] Starting SSH service..."
# 先生成主机密钥（如果不存在）
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    ssh-keygen -A
fi
# 以守护进程方式启动sshd
/usr/sbin/sshd
echo "[INFO] SSH service started"

# ===============================
# 启动 ttyd 并 attach tmux session
# ===============================
echo "[INFO] Starting ttyd, connecting to tmux session: $SESSION_NAME"

# tmux会使用TMUX_TMPDIR环境变量找到正确的socket
TTYD_CMD="tmux attach -t $SESSION_NAME"

if [ -n "$TTYD_USER" ] && [ -n "$TTYD_PASS" ]; then
    echo "[INFO] Starting ttyd with auth..."
    exec env LANG=zh_CN.UTF-8 LC_ALL=zh_CN.UTF-8 ttyd -W -c "$TTYD_USER:$TTYD_PASS" $TTYD_CMD
else
    echo "[INFO] Starting ttyd without auth..."
    exec env LANG=zh_CN.UTF-8 LC_ALL=zh_CN.UTF-8 ttyd -W $TTYD_CMD
fi

# ===============================
# 等待并正确退出
# ===============================
wait -n
exit $?
