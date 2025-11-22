# AMDL-docker

加入了sky佬的wrapper管理网页<https://github.com/sky8282/wrapper-manager-v1> ，以前的登录不再需要;
~~写了一个简单的下载web来调用命令~~，~~不再~~使用ttyd和tmux；

~~由于二开项目越来越多，所以又改了一版，将wrapper排除，转为直接使用itouakirai大佬的~~，然后制作了amdl的编译，同时做了sky8282佬的多线程的编译
攒来自用的一个docker镜像，只适用于内网x86软路由，对于外网使用的，推荐<https://github.com/akina-up/wrapper-amdl>  
说明：  
- 镜像基底：alpine:latest  
- wrapper来源：~~<https://github.com/zhaarey/wrapper> ，未作改动；更换为：<https://github.com/WorldObservationLog/wrapper> ,具体更新了啥我也不清楚，无脑追新。~~ 直接使用 ghcr.io/itouakirai/wrapper:x86
- apple-music-downloader 来源：<https://github.com/zhaarey/apple-music-downloader> ；未作改动,仅编译为二进制 dl
- apple-music-downloader 来源2：<https://github.com/sky8282/apple-music-downloader> ；未作改动，仅编译为二进制 sdl  
- mp4decrypt ~~来源：<https://www.bok.net/Bento4/binaries/Bento4-SDK-1-6-0-641.x86_64-unknown-linux.zip> ;未作mp4decrypt的自动获取新版本，有需求的可自行fork修改action。~~ 已添加编译
- ~~已安装screen,如果需要其他screen配置，建议fork自己搞。~~
- ~~配置ttyd，如需其他ttyd设置比如改端口加密码等，建议fork自己搞。~~  

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
     
　　注意：sky8282佬多线程版需要根据自己实际网络情况配置分片和线程数，这里不提供教程，因为我也不会，我就是瞎试一个不崩的参数就一直用。  

　　注意：~~使用sky8282佬多线程版时关闭ffmpeg修复，因为没有内置ffmpeg，需要该功能的建议本机直接跑而不是用容器，ffmpeg用的地方太多了，容器内置一个的话属于浪费空间。~~ 现在装上了  
 
- 3、第一次wrapper登录，参照原方式：  
打开ip:8080的wrapper-manager-v1界面登录wrapper；  
打开ip:7681的下载页面输入dl -xxxxx命令或sdl -xxxx命令下载；
 
本简易说明只针对技术小白，大佬们请自行修改使用  
