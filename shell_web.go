package main

import (
	"fmt"
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

	// 连接到已经存在的 tmux 会话
	cmd := exec.Command("tmux", "attach-session", "-t", "webterm")
	cmd.Env = append(os.Environ(), "TERM=xterm-256color")
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
button {
    font-size: 14px;
    margin: 2px;
    padding: 4px 8px;
    cursor: pointer;
    background: #222;
    color: #0f0;
    border: 1px solid #0f0;
    border-radius: 4px;
}
</style>
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/xterm@5.1.0/css/xterm.css" />
</head>
<body>
<div id="terminal"></div>
<div style="position: absolute; top: 10px; right: 10px; z-index: 1000;">
    <button id="font-increase">A+</button>
    <button id="font-decrease">A-</button>
</div>
<script src="https://cdn.jsdelivr.net/npm/xterm@5.1.0/lib/xterm.js"></script>
<script>
const term = new Terminal({
    cursorBlink: true,
    theme: { background: '#111', foreground: '#0f0' },
    allowProposedApi: true,
    fontSize: 14,
    termName: 'xterm-256color'
});
term.open(document.getElementById('terminal'));

// WebSocket
const ws = new WebSocket("ws://" + location.host + "/ws");
ws.onmessage = e => term.write(e.data);

// 调整终端尺寸并返回行列
function resizeTerminal() {
    const cols = Math.floor(term.element.offsetWidth / term._core._renderService.dimensions.actualCellWidth);
    const rows = Math.floor(term.element.offsetHeight / term._core._renderService.dimensions.actualCellHeight);
    term.resize(cols, rows);
    return {cols, rows};
}

// 同步行列到服务器
function sendResize() {
    const size = resizeTerminal();
    ws.send(JSON.stringify({cols: size.cols, rows: size.rows}));
}

// 初次连接和窗口变化同步
ws.onopen = sendResize;
window.addEventListener('resize', sendResize);
window.addEventListener('orientationchange', sendResize);

// 字体缩放函数
function changeFontSize(delta) {
    term.setOption('fontSize', term.getOption('fontSize') + delta);
    sendResize();
}

// 按钮事件绑定
document.getElementById('font-increase').addEventListener('click', () => changeFontSize(1));
document.getElementById('font-decrease').addEventListener('click', () => changeFontSize(-1));

term.onData(data => ws.send(data));
term.focus();
</script>
</body>
</html>
`)
}

func main() {
    http.HandleFunc("/", page)
    http.HandleFunc("/ws", wsHandler)
    fmt.Println("Server running on :18888")
    http.ListenAndServe(":18888", nil)
}
