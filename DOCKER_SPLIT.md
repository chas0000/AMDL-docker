# Docker 镜像拆分说明

## 概述

本项目已将 Docker 构建拆分为两个独立的镜像,以提高构建效率和模块化程度。

## 镜像结构

### 1. Wrapper 基础镜像 (`amdl_wrapper`)

**Dockerfile**: `Dockerfile.wrapper`

**包含内容**:
- wrapper (multi-arch) - 从 WorldObservationLog/wrapper 项目下载
- 支持 amd64 和 arm64 架构

**镜像标签**:
- `chaslllll/amdl_wrapper:latest`
- `chaslllll/amdl_wrapper:{BUILD_DATE}`
- `ghcr.io/{actor}/amdl_wrapper:latest`
- `ghcr.io/{actor}/amdl_wrapper:{BUILD_DATE}`

**特点**:
- 独立构建,可单独更新
- 多架构支持 (amd64/arm64)
- 体积较小,仅包含 wrapper 相关文件

### 2. 主应用镜像 (`amdl_m`)

**Dockerfile**: `Dockerfile`

**包含内容**:
- apple-music-downloader (zhaarey 版本)
- apple-music-downloader (sky8282 多线版本)
- GPAC (MP4Box)
- Bento4 (mp4decrypt)
- ttyd (Web 终端)
- 从 wrapper 基础镜像继承的 wrapper 文件

**镜像标签**:
- `chaslllll/amdl_m:latest`
- `chaslllll/amdl_m:amd64-{BUILD_DATE}`
- `chaslllll/amdl_m:arm64-{BUILD_DATE}`
- `ghcr.io/{actor}/amdl_m:latest`
- `ghcr.io/{actor}/amdl_m:amd64-{BUILD_DATE}`
- `ghcr.io/{actor}/amdl_m:arm64-{BUILD_DATE}`

**特点**:
- 依赖 wrapper 基础镜像
- 使用多阶段构建从基础镜像获取 wrapper 文件
- 包含所有 Apple Music 下载和解密工具

## 构建流程

### GitHub Actions Workflows

现在有两个独立的 workflow:

#### 1. Wrapper 基础镜像构建 ([build-wrapper.yml](.github/workflows/build-wrapper.yml))

**触发条件**:
- 手动触发 (`workflow_dispatch`)
- 推送更改到 `main` 分支且修改了以下文件:
  - `Dockerfile.wrapper`
  - `.github/workflows/build-wrapper.yml`

**构建内容**:
- 构建并推送 wrapper 基础镜像 (multi-arch: amd64/arm64)

**特点**:
- 独立运行,不依赖其他 workflow
- 仅在 wrapper 相关文件变化时触发
- 构建速度快,因为只处理 wrapper 下载

#### 2. 主应用镜像构建 ([build-amdl.yml](.github/workflows/build-amdl.yml))

**触发条件**:
- 手动触发 (`workflow_dispatch`)
- 推送更改到 `main` 分支且修改了以下文件:
  - `Dockerfile`
  - `start.sh`
  - `shell_web.go`
  - `.github/workflows/build-amdl.yml`
  - `output/**`
  - `backup/**`

**构建顺序**:
1. **pre-build**: 编译所有 Go 程序和下载依赖
   - apple-music-downloader (zhaarey 版本)
   - apple-music-downloader (sky8282 多线版本)
   - wrapper-manager-v1
   - ttyd (Web 终端)
   - wrapper (multi-arch) - 仅用于备用,实际从基础镜像获取
2. **build-amd64**: 构建 amd64 主镜像
3. **build-arm64**: 构建 arm64 主镜像
4. **create-multiarch**: 创建 multi-arch manifest

**特点**:
- 独立运行,不依赖 wrapper workflow
- 使用 Docker 多阶段构建从已发布的 wrapper 基础镜像获取文件
- 可以利用 Docker 层缓存加速构建

### 本地构建

#### 构建 Wrapper 基础镜像

```bash
# 构建 amd64
docker buildx build --platform linux/amd64 -t chaslllll/amdl_wrapper:latest -f Dockerfile.wrapper .

# 构建 arm64
docker buildx build --platform linux/arm64 -t chaslllll/amdl_wrapper:latest -f Dockerfile.wrapper .

# 构建 multi-arch
docker buildx build --platform linux/amd64,linux/arm64 -t chaslllll/amdl_wrapper:latest -f Dockerfile.wrapper --push .
```

#### 构建主应用镜像

```bash
# 首先需要确保 wrapper 基础镜像已构建并可用

# 构建 amd64
docker buildx build --platform linux/amd64 -t chaslllll/amdl_m:latest .

# 构建 arm64
docker buildx build --platform linux/arm64 -t chaslllll/amdl_m:latest .

# 构建 multi-arch
docker buildx build --platform linux/amd64,linux/arm64 -t chaslllll/amdl_m:latest --push .
```

## 优势

1. **完全独立**: 两个 workflow 互不依赖,可以独立触发和构建
2. **模块化**: wrapper 组件独立,可单独更新和维护
3. **构建效率**: 
   - Wrapper 镜像变化少,很少需要重新构建
   - 主镜像利用 Docker 层缓存,从已发布的基础镜像快速获取 wrapper
4. **灵活性**: 
   - 可以独立发布 wrapper 基础镜像的更新
   - 可以独立发布主应用镜像的更新
   - 减少不必要的构建,节省 CI/CD 资源
5. **清晰度**: 职责分离,每个 workflow 专注特定功能
6. **路径触发**: 仅在相关文件变化时自动触发,避免无效构建

## 注意事项

- **首次构建顺序**: 首次使用时,需要先手动触发 `build-wrapper.yml` 构建 wrapper 基础镜像,然后再触发 `build-amdl.yml`
- **主镜像依赖**: 主镜像通过 Docker 多阶段构建从 `chaslllll/amdl_wrapper:latest` 获取 wrapper 文件,确保该镜像已推送到仓库
- **独立更新**: 
  - 如果只修改了 wrapper 相关内容,只需触发 `build-wrapper.yml`
  - 如果只修改了主应用相关内容,只需触发 `build-amdl.yml`
- **docker-compose.yml**: 无需修改,仍使用主镜像 `chaslllll/amdl_m:latest`
- **自动触发**: 两个 workflow 都配置了路径触发,只有相关文件变化时才会自动构建

## 文件变更总结

### 新增文件
- `Dockerfile.wrapper`: Wrapper 基础镜像的 Dockerfile
- `.github/workflows/build-wrapper.yml`: Wrapper 基础镜像的独立 workflow
- `.github/workflows/build-amdl.yml`: 主应用镜像的独立 workflow
- `DOCKER_SPLIT.md`: 本说明文档

### 修改文件
- `Dockerfile`: 使用多阶段构建从 wrapper 基础镜像获取文件

### 删除文件
- `.github/workflows/build-docker.yml`: 旧的统一 workflow (已拆分为两个独立 workflow)

### 未修改文件
- `docker-compose.yml`: 保持不变,继续使用主镜像
