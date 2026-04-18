# 快速开始 - 独立 Workflow 使用指南

## 📌 首次使用

### 步骤 1: 构建 Wrapper 基础镜像

在 GitHub Actions 中手动触发 `构建 Wrapper 基础镜像` workflow:

1. 进入仓库的 **Actions** 标签页
2. 选择 **构建 Wrapper 基础镜像** workflow
3. 点击 **Run workflow** 按钮
4. 等待构建完成 (约 2-3 分钟)

### 步骤 2: 构建主应用镜像

Wrapper 基础镜像构建完成后,触发 `构建主应用镜像` workflow:

1. 进入仓库的 **Actions** 标签页
2. 选择 **构建主应用镜像** workflow
3. 点击 **Run workflow** 按钮
4. 等待构建完成 (约 10-15 分钟)

## 🔄 日常使用

### 场景 1: 只更新了 Wrapper 相关内容

如果只修改了:
- `Dockerfile.wrapper`
- `.github/workflows/build-wrapper.yml`

**操作**: 只需触发 `构建 Wrapper 基础镜像` workflow

### 场景 2: 只更新了主应用相关内容

如果只修改了:
- `Dockerfile`
- `start.sh`
- `shell_web.go`
- `.github/workflows/build-amdl.yml`
- `output/**`
- `backup/**`

**操作**: 只需触发 `构建主应用镜像` workflow

### 场景 3: 同时更新了两部分内容

**操作**: 
1. 先触发 `构建 Wrapper 基础镜像` workflow
2. 等待完成后,再触发 `构建主应用镜像` workflow

## 🚀 自动触发

两个 workflow 都配置了路径触发:

- **build-wrapper.yml**: 当 `Dockerfile.wrapper` 或 `.github/workflows/build-wrapper.yml` 变化时自动触发
- **build-amdl.yml**: 当 `Dockerfile`、`start.sh`、`shell_web.go` 等相关文件变化时自动触发

## 📦 镜像标签

### Wrapper 基础镜像
```
chaslllll/amdl_wrapper:latest
chaslllll/amdl_wrapper:{BUILD_DATE}
ghcr.io/{actor}/amdl_wrapper:latest
ghcr.io/{actor}/amdl_wrapper:{BUILD_DATE}
```

### 主应用镜像
```
chaslllll/amdl_m:latest
chaslllll/amdl_m:amd64-{BUILD_DATE}
chaslllll/amdl_m:arm64-{BUILD_DATE}
ghcr.io/{actor}/amdl_m:latest
ghcr.io/{actor}/amdl_m:amd64-{BUILD_DATE}
ghcr.io/{actor}/amdl_m:arm64-{BUILD_DATE}
```

## ⚠️ 重要提示

1. **首次使用必须先构建 wrapper 基础镜像**,否则主镜像构建会失败
2. 主镜像通过 Docker 多阶段构建从 `chaslllll/amdl_wrapper:latest` 获取 wrapper 文件
3. 如果 wrapper 基础镜像更新后,建议重新构建主应用镜像以获取最新版本
4. docker-compose.yml 无需修改,仍使用 `chaslllll/amdl_m:latest`

## 🔍 查看构建状态

1. 进入仓库的 **Actions** 标签页
2. 查看对应的 workflow 运行状态
3. 点击具体的运行记录查看详细日志
4. 构建成功后会在 Summary 中显示镜像标签信息

## 💡 最佳实践

1. **定期更新**: 建议定期手动触发两个 workflow,确保使用最新的基础组件
2. **版本管理**: 使用带日期的标签进行版本管理,便于回滚
3. **缓存利用**: Docker 层缓存会自动利用,相同内容的层不会重复构建
4. **监控构建**: 关注构建时间和成功率,及时发现潜在问题
