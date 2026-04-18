# 测试和合并指南

## ✅ 已完成的操作

所有更改已推送到特性分支: **`feature/split-docker-workflows`**

当前 main 分支**未受影响**,仍然保持原样。

## 📋 测试步骤

### 1. 在 GitHub 上查看 Pull Request

访问以下链接创建 Pull Request:
```
https://github.com/chas0000/AMDL-docker/pull/new/feature/split-docker-workflows
```

或者:
1. 进入你的 GitHub 仓库
2. 点击 **Pull requests** 标签
3. 点击 **New pull request**
4. 选择 `feature/split-docker-workflows` → `main`

### 2. 审查更改

在 Pull Request 页面中,你可以:
- 查看所有文件更改
- 查看提交历史
- 阅读变更说明

### 3. 触发 Workflow 测试

#### 方法 A: 通过 Pull Request 自动触发
- 推送代码到特性分支后,GitHub Actions 会自动运行 workflows
- 但注意:workflows 配置为只在 `main` 分支的特定路径变化时触发
- 所以可能需要手动触发

#### 方法 B: 手动触发 Workflow (推荐)

1. 切换到特性分支:
   ```bash
   git checkout feature/split-docker-workflows
   ```

2. 在 GitHub 上手动触发 workflows:
   - 进入 **Actions** 标签页
   - 选择 **构建 Wrapper 基础镜像** workflow
   - 点击 **Run workflow**
   - 选择分支: `feature/split-docker-workflows`
   - 点击 **Run workflow** 按钮

3. 等待 wrapper 基础镜像构建完成 (约 2-3 分钟)

4. 然后触发主应用镜像 workflow:
   - 选择 **构建主应用镜像** workflow
   - 点击 **Run workflow**
   - 选择分支: `feature/split-docker-workflows`
   - 点击 **Run workflow** 按钮

5. 等待主应用镜像构建完成 (约 10-15 分钟)

### 4. 验证构建结果

检查以下内容:

#### Wrapper 基础镜像
- ✅ Workflow 是否成功完成
- ✅ Docker Hub 上是否有新镜像: `chaslllll/amdl_wrapper:latest`
- ✅ GHCR 上是否有新镜像: `ghcr.io/chas0000/amdl_wrapper:latest`

#### 主应用镜像
- ✅ Workflow 是否成功完成
- ✅ Docker Hub 上是否有新镜像: `chaslllll/amdl_m:latest`
- ✅ GHCR 上是否有新镜像: `ghcr.io/chas0000/amdl_m:latest`
- ✅ 多架构 manifest 是否正确创建

### 5. 本地测试 (可选)

如果你想先在本地测试:

```bash
# 拉取特性分支
git checkout feature/split-docker-workflows

# 本地构建 wrapper 基础镜像
docker buildx build --platform linux/amd64,linux/arm64 \
  -t chaslllll/amdl_wrapper:test \
  -f Dockerfile.wrapper .

# 本地构建主应用镜像
docker buildx build --platform linux/amd64,linux/arm64 \
  -t chaslllll/amdl_m:test .

# 测试运行
docker run --rm -it chaslllll/amdl_m:test bash
```

## 🔀 合并到 Main 分支

测试通过后,有两种方式合并:

### 方式 1: 通过 GitHub Pull Request (推荐)

1. 在 Pull Request 页面点击 **Merge pull request**
2. 确认合并信息
3. 点击 **Confirm merge**
4. 删除特性分支 (可选)

**优点**:
- 有完整的审查记录
- 可以添加评论和讨论
- 一键合并,简单安全

### 方式 2: 通过命令行合并

```bash
# 切换回 main 分支
git checkout main

# 拉取最新代码
git pull origin main

# 合并特性分支
git merge feature/split-docker-workflows

# 推送到远程
git push origin main

# 删除本地特性分支 (可选)
git branch -d feature/split-docker-workflows

# 删除远程特性分支 (可选)
git push origin --delete feature/split-docker-workflows
```

## ⚠️ 注意事项

### 1. 首次构建顺序
合并到 main 后,首次使用时需要:
1. 先触发 `build-wrapper.yml` 构建 wrapper 基础镜像
2. 再触发 `build-amdl.yml` 构建主应用镜像

### 2. 镜像标签
- 测试时可以使用不同的标签 (如 `:test`) 避免覆盖生产镜像
- 正式合并后会使用 `:latest` 和带日期的标签

### 3. 回滚方案
如果合并后发现问题:
```bash
# 回滚到上一个提交
git revert HEAD

# 或者重置到之前的提交
git reset --hard <previous-commit-hash>
git push origin main --force
```

### 4. Workflows 触发
合并到 main 后:
- 修改 `Dockerfile.wrapper` 会自动触发 `build-wrapper.yml`
- 修改 `Dockerfile` 等文件会自动触发 `build-amdl.yml`
- 也可以随时手动触发

## 🎯 快速测试清单

- [ ] 特性分支已推送到 GitHub
- [ ] Pull Request 已创建
- [ ] Wrapper 基础镜像 workflow 测试成功
- [ ] 主应用镜像 workflow 测试成功
- [ ] Docker Hub 镜像已更新
- [ ] GHCR 镜像已更新
- [ ] 本地测试通过 (可选)
- [ ] 文档审查完成
- [ ] 准备合并到 main

## 📞 需要帮助?

如果测试过程中遇到问题:

1. 查看 workflow 运行日志
2. 检查 Docker 构建输出
3. 验证环境变量和 secrets 配置
4. 查看文档: `DOCKER_SPLIT.md`, `QUICK_START.md`

## 🎉 总结

现在你可以:
1. ✅ 在特性分支上安全测试
2. ✅ 不影响现有的 main 分支
3. ✅ 随时可以回滚或修改
4. ✅ 测试通过后再合并到 main

祝测试顺利! 🚀
