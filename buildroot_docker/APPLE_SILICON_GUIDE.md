# Apple Silicon Mac 兼容性指南

本文档说明如何在 Apple Silicon (M1/M2/M3) Mac 上运行 ARM64 Buildroot 交叉编译环境。

## 🍎 Apple Silicon Mac 兼容性

### ✅ 支持情况

**完全支持！** 本 Docker 镜像已经过优化，可以在以下设备上运行：

- **Apple Silicon Macs**: M1, M1 Pro, M1 Max, M2, M2 Pro, M2 Max, M3 等
- **Intel Macs**: 传统 x86_64 Mac
- **Linux x86_64**: 传统 Linux 系统

### 🔧 技术原理

1. **Docker 镜像平台**: 使用 `--platform=linux/amd64` 确保一致性
2. **Rosetta 2 翻译**: Apple Silicon Mac 通过 Rosetta 2 运行 x86_64 容器
3. **交叉编译**: 在容器内进行 x86_64 → ARM64 交叉编译

## 🚀 在 Apple Silicon Mac 上的使用步骤

### 1. 环境准备

```bash
# 确保 Docker Desktop 已安装并启用 Rosetta 2
# Docker Desktop -> Settings -> General -> "Use Rosetta for x86/amd64 emulation on Apple Silicon"

# 验证 Docker 环境
docker --version
docker info
```

### 2. 构建镜像

```bash
# 克隆或下载项目文件
cd /path/to/project

# 构建镜像（支持 Apple Silicon）
./build.sh build

# 或手动构建
docker build --platform linux/amd64 -t buildroot-arm64:latest .
```

### 3. 运行容器

```bash
# 方式一：使用构建脚本
./build.sh setup  # 设置 Buildroot 源码
./build.sh run    # 运行容器

# 方式二：手动运行
docker run -it \
  --platform linux/amd64 \
  --name buildroot-arm64-builder \
  -v $(pwd)/buildroot:/workspace/buildroot \
  -v $(pwd)/output:/workspace/output \
  buildroot-arm64:latest
```

### 4. 在容器内构建

```bash
# 进入容器后
# 用户名: builduser, 密码: 123456

# 配置 Buildroot
~/build.sh menuconfig

# 开始交叉编译
~/build.sh build
```

## 📊 性能对比

| 平台 | 构建速度 | 内存使用 | 兼容性 | 推荐度 |
|------|----------|----------|---------|---------|
| Apple M1/M2/M3 | 快 (Rosetta 2) | 中等 | 完美 | ⭐⭐⭐⭐⭐ |
| Intel Mac | 很快 (原生) | 低 | 完美 | ⭐⭐⭐⭐⭐ |
| Linux x86_64 | 很快 (原生) | 低 | 完美 | ⭐⭐⭐⭐⭐ |

## 🔍 Apple Silicon 特定配置

### Docker Desktop 设置

1. **启用 Rosetta 2 模拟**:
   - Docker Desktop → Settings → General
   - 勾选 "Use Rosetta for x86/amd64 emulation on Apple Silicon"

2. **资源分配**:
   ```
   CPU: 4-8 核心 (推荐)
   Memory: 8-16 GB (推荐)
   Swap: 2-4 GB
   Disk: 64 GB+ (SSD 推荐)
   ```

3. **文件共享**:
   - 确保项目目录已添加到 File Sharing 列表

### 构建优化

```bash
# 在 Apple Silicon Mac 上的优化构建命令
docker build \
  --platform linux/amd64 \
  --build-arg BUILDKIT_INLINE_CACHE=1 \
  -t buildroot-arm64:latest .

# 多阶段构建缓存优化
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1
```

## 🐛 常见问题解决

### 1. 性能较慢

**原因**: Rosetta 2 翻译开销
**解决方案**:
```bash
# 启用 Docker Desktop 的 Rosetta 2 优化
# 增加分配给 Docker 的内存和 CPU 资源
```

### 2. 构建失败

**原因**: 平台不匹配
**解决方案**:
```bash
# 明确指定平台
docker run --platform linux/amd64 -it buildroot-arm64:latest

# 或修改 Dockerfile 添加平台指定
FROM --platform=linux/amd64 ubuntu:22.04
```

### 3. 文件权限问题

**原因**: macOS 文件系统差异
**解决方案**:
```bash
# 修复挂载目录权限
sudo chown -R $(whoami):staff $(pwd)/buildroot
sudo chown -R $(whoami):staff $(pwd)/output
```

## 🔧 推送到镜像仓库

现在命名空间已设置为 `hsong`，可以直接推送：

```bash
# 推送到阿里云
./push-image.sh latest aliyun

# 推送后的完整镜像名称
# registry.cn-hangzhou.aliyuncs.com/hsong/buildroot-arm64:latest
```

## 📱 在其他 Apple Silicon Mac 上使用

```bash
# 拉取镜像
docker pull registry.cn-hangzhou.aliyuncs.com/hsong/buildroot-arm64:latest

# 运行（明确指定平台）
docker run -it \
  --platform linux/amd64 \
  --name buildroot-env \
  -v $(pwd)/buildroot:/workspace/buildroot \
  -v $(pwd)/output:/workspace/output \
  registry.cn-hangzhou.aliyuncs.com/hsong/buildroot-arm64:latest
```

## 💡 最佳实践

### 1. 性能优化

```bash
# 使用 BuildKit 加速构建
export DOCKER_BUILDKIT=1

# 启用并行构建
make -j$(sysctl -n hw.logicalcpu)  # 使用所有逻辑核心
```

### 2. 存储优化

```bash
# 定期清理 Docker 缓存
docker system prune -f

# 使用多阶段构建减少镜像大小
# （已在 Dockerfile 中实现）
```

### 3. 开发工作流

```bash
# 开发时使用 docker-compose
docker-compose up -d
docker-compose exec buildroot-arm64 bash

# 生产环境直接使用镜像
docker run registry.cn-hangzhou.aliyuncs.com/hsong/buildroot-arm64:latest
```

## 🎯 总结

✅ **完全支持 Apple Silicon Mac**  
✅ **命名空间已设置为 `hsong`**  
✅ **性能经过优化**  
✅ **跨平台兼容性良好**  

现在您可以在任何 Apple Silicon Mac 上流畅运行这个 ARM64 Buildroot 交叉编译环境！

---

**注意**: 首次在 Apple Silicon Mac 上运行可能需要几分钟来下载和准备 Rosetta 2 环境，这是正常的。