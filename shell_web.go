package main

import (
	"encoding/json"
	"fmt"
	"github.com/creack/pty"
	"github.com/gorilla/websocket"
	"net/http"
	"os/exec"
	"os"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool { return true },
}

func wsHandler(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		fmt.Println("Upgrade error:", err)
		return
	}
	defer conn.Close()

	// 固定 tmux 会话名
	sessionName := "webterm"
	cmd := exec.Command("tmux", "new-session", "-A", "-s", sessionName)

	ptmx, err := pty.Start(cmd)
	if err != nil {
		fmt.Println("PTY start error:", err)
		return
	}
	defer ptmx.Close()

	// PTY -> WS
	go func() {
		buf := make([]byte, 1024)
		for {
			n, err := ptmx.Read(buf)
			if err != nil {
				return
			}
			conn.WriteMessage(websocket.TextMessage, buf[:n])
		}
	}()

	// WS -> PTY
	for {
		_, msg, err := conn.ReadMessage()
		if err != nil {
			return
		}

		// 尝试解析 resize 消息
		var m map[string]int
		if err := json.Unmarshal(msg, &m); err == nil {
			if c, ok := m["cols"]; ok {
				if r, ok := m["rows"]; ok {
					pty.Setsize(ptmx, &pty.Winsize{Cols: uint16(c), Rows: uint16(r)})
					continue
				}
			}
		}

		ptmx.Write(msg)
	}
}

func page(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/html; charset=UTF-8")
	fmt.Fprint(w, `
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover, user-scalable=no">
<style>
html, body {
	margin: 0;
	padding: 0;
	height: 100vh;
	width: 100vw;
	background: #111;
	color: #0f0;
	overflow: hidden;
}
#terminal {
	width: 100%;
	height: 100%;
}
.xterm-viewport {
	width: 100% !important;
}
</style>
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/xterm@5.1.0/css/xterm.css" />
</head>
<body>
<div id="terminal"></div>
<script src="https://cdn.jsdelivr.net/npm/xterm@5.1.0/lib/xterm.js"></script>
<script>
const term = new Terminal({
	cursorBlink: true,
	theme: { background: '#111', foreground: '#0f0' },
	allowProposedApi: true,
	fontSize: 16
});
term.open(document.getElementById('terminal'));

// 计算浏览器窗口字符尺寸
function resizeTerminal() {
	const width = window.innerWidth;
	const height = window.innerHeight;
	const charWidth = 9;
	const charHeight = 17;
	const cols = Math.floor(width / charWidth);
	const rows = Math.floor(height / charHeight);
	term.resize(cols, rows);
	return {cols, rows};
}

// WebSocket
const ws = new WebSocket("ws://" + location.host + "/ws");
ws.onmessage = e => term.write(e.data);

// 发送 resize 信息给服务器
function sendResize() {
	const size = resizeTerminal();
	ws.send(JSON.stringify({cols: size.cols, rows: size.rows}));
}

// 初次连接和窗口变化都同步
ws.onopen = sendResize;
window.addEventListener('resize', sendResize);
window.addEventListener('orientationchange', sendResize);

term.onData(data => ws.send(data));
term.focus();
</script>
</body>
</html>
`)
}

func main() {
	// 确保 tmux 可执行
	if _, err := exec.LookPath("tmux"); err != nil {
		fmt.Println("tmux not found:", err)
		os.Exit(1)
	}

	http.HandleFunc("/", page)
	http.HandleFunc("/ws", wsHandler)
	fmt.Println("Server running on :18888")
	http.ListenAndServe(":18888", nil)
}
