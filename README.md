# AMDL-docker

由于sky佬的wrapper-manager-v1功能强大，第一次运行必须配置好wm_config.yaml和sky_config.yaml;wm_config.yaml中需要将json的位置改为/app/config/manager.json，wrapper位置不要修改，然后对应账号区域端口修改

加入了sky佬的wrapper管理网页<https://github.com/sky8282/wrapper-manager-v1> ，以前的登录不再需要;
~~写了一个简单的下载web来调用命令~~，~~不再~~使用ttyd和tmux；

~~由于二开项目越来越多，所以又改了一版，将wrapper排除，转为直接使用itouakirai大佬的~~，然后制作了amdl的编译，同时做了sky8282佬的多线程的编译
攒来自用的一个docker镜像，只适用于内网x86软路由，对于外网使用的，推荐<https://github.com/akina-up/wrapper-amdl>  
说明：  
- 镜像基底：ubuntu:22.04  
- wrapper来源：~~<https://github.com/zhaarey/wrapper> ，未作改动；更换为：<https://github.com/WorldObservationLog/wrapper> ,具体更新了啥我也不清楚，无脑追新。~~ 直接使用 ghcr.io/itouakirai/wrapper:x86
- apple-music-downloader 来源：<https://github.com/zhaarey/apple-music-downloader> ；未作改动,仅编译为二进制 dl
- apple-music-downloader 来源2：<https://github.com/sky8282/apple-music-downloader> ；未作改动，仅编译为二进制 sdl  
- mp4decrypt ~~来源：<https://www.bok.net/Bento4/binaries/Bento4-SDK-1-6-0-641.x86_64-unknown-linux.zip> ;未作mp4decrypt的自动获取新版本，有需求的可自行fork修改action。~~ 已添加编译
- ~~已安装screen,如果需要其他screen配置，建议fork自己搞。~~
- ~~配置ttyd，如需其他ttyd设置比如改端口加密码等，建议fork自己搞。~~  
- **新增SSH服务支持**，可通过SSH直接连接到tmux session  

使用简易说明：  
- 1、建议使用compose方式管理，cli方式也可以，但是需要自己管理路径，以下说明均安装compose方式；  
- 2、建立项目compose目录，例如：
<pre>
/docker/wrapper-amdl/  
    ├── config/  
    ├── instances/  
    └── docker-compose.yml  

</pre></div>  


　　config放置两个配置文件 config.yaml为zhaarey佬原版，对应dl命令使用；sky_config.yaml为sky8282佬多线程版，对应sdl使用。 

  .tmux.conf为tmux的配置文件，自己按需修改后放在config目录下脚本会自动调用。  
     
　　注意：sky8282佬多线程版需要根据自己实际网络情况配置分片和线程数，这里不提供教程，因为我也不会，我就是瞎试一个不崩的参数就一直用。  

　　注意：~~使用sky8282佬多线程版时关闭ffmpeg修复，因为没有内置ffmpeg，需要该功能的建议本机直接跑而不是用容器，ffmpeg用的地方太多了，容器内置一个的话属于浪费空间。~~ 现在装上了  
 
- 3、第一次wrapper登录，参照原方式：  
打开ip:8080的wrapper-manager-v1界面登录wrapper；  
打开ip:7681的下载页面输入dl -xxxxx命令或sdl -xxxx命令下载；

## SSH访问功能

本镜像现已支持通过SSH直接连接到tmux session，**SSH用户与ttyd使用相同权限（root）**：

### SSH连接方式

**默认端口（22）：**
```bash
ssh root@your-container-ip
# 默认密码: password
```

**自定义端口：**
```bash
ssh root@your-container-ip -p 2222
# 默认密码: password
```

### 环境变量配置
在docker-compose.yml中设置：
```yaml
environment:
  SSH_USER: "root"              # SSH用户名（默认：root）
  SSH_PASSWORD: "password"      # SSH密码（默认：password）
  SSH_PORT: "2222"              # SSH端口（默认：22）
```

### 使用场景

**1. Bridge 网络模式（推荐新手）：**
```yaml
network_mode: bridge
ports:
  - "7681:7681"    # ttyd
  - "2122:22"      # SSH映射到宿主机2122端口
```
连接：`ssh root@localhost -p 2122`

**2. Host 网络模式（高性能）：**
```yaml
network_mode: host
environment:
  SSH_PORT: "2222"  # 修改SSH端口避免与宿主机冲突
```
连接：`ssh root@localhost -p 2222`

### SSH特性
- **与ttyd完全相同的root权限**
- 连接后自动attach到amdl tmux session
- SSH和ttyd共享同一个session，可以看到彼此的操作
- 如果session不存在则自动创建
- 支持密码认证登录
- 支持自定义端口（host模式下特别有用）
 
本简易说明只针对技术小白，大佬们请自行修改使用  
