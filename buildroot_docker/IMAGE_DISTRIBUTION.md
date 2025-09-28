# Docker 镜像分发指南

本文档介绍如何将构建好的 ARM64 Buildroot Docker 镜像分发到中国可访问的镜像仓库。

## 🏷️ 用户信息

**默认用户配置：**
- 用户名：`builduser`
- 密码：`123456`
- 权限：sudo 权限，可以安装软件和使用 root 权限

## 📦 支持的镜像仓库

### 1. 阿里云容器镜像服务 (推荐)

**优势：**
- 中国大陆访问速度快
- 免费个人版支持无限私有仓库
- 支持海外同步

**使用步骤：**

```bash
# 1. 登录阿里云容器镜像服务
# 访问：https://cr.console.aliyun.com/

# 2. 创建命名空间（如：your-namespace）

# 3. 构建并标记镜像
docker build -t buildroot-arm64:latest .

# 4. 标记镜像到阿里云
docker tag buildroot-arm64:latest registry.cn-hangzhou.aliyuncs.com/your-namespace/buildroot-arm64:latest

# 5. 登录阿里云镜像仓库
docker login --username=your-aliyun-username registry.cn-hangzhou.aliyuncs.com

# 6. 推送镜像
docker push registry.cn-hangzhou.aliyuncs.com/your-namespace/buildroot-arm64:latest

# 7. 在其他机器上拉取
docker pull registry.cn-hangzhou.aliyuncs.com/your-namespace/buildroot-arm64:latest
```

### 2. 腾讯云容器镜像服务

```bash
# 1. 访问：https://console.cloud.tencent.com/tcr

# 2. 标记镜像
docker tag buildroot-arm64:latest ccr.ccs.tencentyun.com/your-namespace/buildroot-arm64:latest

# 3. 登录腾讯云
docker login ccr.ccs.tencentyun.com --username=your-tencent-username

# 4. 推送镜像
docker push ccr.ccs.tencentyun.com/your-namespace/buildroot-arm64:latest
```

### 3. 华为云容器镜像服务

```bash
# 1. 访问：https://console.huaweicloud.com/swr/

# 2. 标记镜像
docker tag buildroot-arm64:latest swr.cn-north-4.myhuaweicloud.com/your-namespace/buildroot-arm64:latest

# 3. 登录华为云
docker login -u cn-north-4@your-access-key -p your-secret-key swr.cn-north-4.myhuaweicloud.com

# 4. 推送镜像
docker push swr.cn-north-4.myhuaweicloud.com/your-namespace/buildroot-arm64:latest
```

### 4. 网易云镜像仓库

```bash
# 1. 访问：https://c.163yun.com/hub

# 2. 标记镜像
docker tag buildroot-arm64:latest hub.c.163.com/your-namespace/buildroot-arm64:latest

# 3. 登录网易云
docker login hub.c.163.com

# 4. 推送镜像
docker push hub.c.163.com/your-namespace/buildroot-arm64:latest
```

## 🔧 自动化构建和推送脚本

创建一个自动化脚本 `push-image.sh`：

```bash
#!/bin/bash

set -e

# 配置参数
IMAGE_NAME="buildroot-arm64"
VERSION=${1:-latest}
REGISTRY=${2:-aliyun}  # 默认使用阿里云

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 镜像仓库配置
case $REGISTRY in
    "aliyun")
        REGISTRY_URL="registry.cn-hangzhou.aliyuncs.com"
        NAMESPACE="your-namespace"  # 请替换为您的命名空间
        ;;
    "tencent")
        REGISTRY_URL="ccr.ccs.tencentyun.com"
        NAMESPACE="your-namespace"
        ;;
    "huawei")
        REGISTRY_URL="swr.cn-north-4.myhuaweicloud.com"
        NAMESPACE="your-namespace"
        ;;
    "netease")
        REGISTRY_URL="hub.c.163.com"
        NAMESPACE="your-namespace"
        ;;
    *)
        log_error "不支持的镜像仓库: $REGISTRY"
        echo "支持的选项: aliyun, tencent, huawei, netease"
        exit 1
        ;;
esac

REMOTE_IMAGE="$REGISTRY_URL/$NAMESPACE/$IMAGE_NAME:$VERSION"

log_info "准备推送镜像到: $REMOTE_IMAGE"

# 检查本地镜像是否存在
if ! docker image inspect "$IMAGE_NAME:$VERSION" &> /dev/null; then
    log_error "本地镜像 $IMAGE_NAME:$VERSION 不存在，请先构建镜像"
    exit 1
fi

# 标记镜像
log_info "标记镜像..."
docker tag "$IMAGE_NAME:$VERSION" "$REMOTE_IMAGE"

# 推送镜像
log_info "推送镜像到远程仓库..."
docker push "$REMOTE_IMAGE"

log_info "镜像推送完成！"
log_info "拉取命令: docker pull $REMOTE_IMAGE"
```

## 🚀 使用示例

### 构建和推送镜像

```bash
# 1. 构建镜像
./build.sh build

# 2. 推送到阿里云（推荐）
chmod +x push-image.sh
./push-image.sh latest aliyun

# 3. 在其他机器上拉取使用
docker pull registry.cn-hangzhou.aliyuncs.com/your-namespace/buildroot-arm64:latest
docker run -it registry.cn-hangzhou.aliyuncs.com/your-namespace/buildroot-arm64:latest
```

### 在新机器上使用

```bash
# 1. 拉取镜像
docker pull registry.cn-hangzhou.aliyuncs.com/your-namespace/buildroot-arm64:latest

# 2. 运行容器
docker run -it \
  --name buildroot-env \
  -v $(pwd)/buildroot:/workspace/buildroot \
  -v $(pwd)/output:/workspace/output \
  registry.cn-hangzhou.aliyuncs.com/your-namespace/buildroot-arm64:latest

# 3. 在容器内使用 sudo（密码: 123456）
sudo apt update
sudo apt install -y vim
```

## 📊 镜像仓库对比

| 服务商 | 免费额度 | 网络速度 | 稳定性 | 推荐度 |
|--------|----------|----------|---------|--------|
| 阿里云 | 无限私有仓库 | 很快 | 很高 | ⭐⭐⭐⭐⭐ |
| 腾讯云 | 10GB 存储 | 很快 | 高 | ⭐⭐⭐⭐ |
| 华为云 | 5GB 存储 | 快 | 高 | ⭐⭐⭐⭐ |
| 网易云 | 1GB 存储 | 中等 | 中等 | ⭐⭐⭐ |

## 🔐 安全建议

1. **使用私有仓库**: 避免将包含敏感信息的镜像设为公开
2. **定期更新密码**: 定期更换镜像仓库的访问密码
3. **使用访问令牌**: 优先使用访问令牌而非密码登录
4. **镜像扫描**: 定期扫描镜像漏洞

## 📝 注意事项

1. 请将 `your-namespace` 替换为您实际的命名空间名称
2. 首次推送前需要在对应的云平台创建镜像仓库
3. 镜像大小约 2-3GB，请确保网络环境良好
4. 建议为不同版本打不同的标签，方便版本管理

---

**推荐方案**: 使用阿里云容器镜像服务，速度快、稳定性高，且对中国用户免费提供充足的配额。