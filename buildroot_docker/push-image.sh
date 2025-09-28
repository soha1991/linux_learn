#!/bin/bash

# Docker 镜像自动推送脚本
# 支持推送到中国主要的容器镜像仓库

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

# 函数定义
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_usage() {
    echo -e "${BLUE}Docker 镜像推送脚本${NC}"
    echo ""
    echo "用法: $0 [版本] [仓库]"
    echo ""
    echo "参数:"
    echo "  版本    镜像版本标签 (默认: latest)"
    echo "  仓库    目标镜像仓库 (默认: aliyun)"
    echo ""
    echo "支持的仓库:"
    echo "  aliyun   - 阿里云容器镜像服务 (推荐)"
    echo "  tencent  - 腾讯云容器镜像服务"
    echo "  huawei   - 华为云容器镜像服务"
    echo "  netease  - 网易云镜像仓库"
    echo "  dockerhub - Docker Hub (需要科学上网)"
    echo ""
    echo "示例:"
    echo "  $0                    # 推送 latest 版本到阿里云"
    echo "  $0 v1.0 tencent      # 推送 v1.0 版本到腾讯云"
    echo "  $0 latest huawei     # 推送 latest 版本到华为云"
    echo ""
}

# 检查参数
if [[ "$1" == "help" || "$1" == "--help" || "$1" == "-h" ]]; then
    print_usage
    exit 0
fi

# 镜像仓库配置
case $REGISTRY in
    "aliyun")
        REGISTRY_URL="registry.cn-hangzhou.aliyuncs.com"
        NAMESPACE="hsong"  # 命名空间设置为 hsong
        LOGIN_SERVER="registry.cn-hangzhou.aliyuncs.com"
        ;;
    "tencent")
        REGISTRY_URL="ccr.ccs.tencentyun.com"
        NAMESPACE="hsong"
        LOGIN_SERVER="ccr.ccs.tencentyun.com"
        ;;
    "huawei")
        REGISTRY_URL="swr.cn-north-4.myhuaweicloud.com"
        NAMESPACE="hsong"
        LOGIN_SERVER="swr.cn-north-4.myhuaweicloud.com"
        ;;
    "netease")
        REGISTRY_URL="hub.c.163.com"
        NAMESPACE="hsong"
        LOGIN_SERVER="hub.c.163.com"
        ;;
    "dockerhub")
        REGISTRY_URL="docker.io"
        NAMESPACE="hsong"  # Docker Hub 用户名设置为 hsong
        LOGIN_SERVER=""
        ;;
    *)
        log_error "不支持的镜像仓库: $REGISTRY"
        echo ""
        print_usage
        exit 1
        ;;
esac

if [[ "$REGISTRY" == "dockerhub" ]]; then
    REMOTE_IMAGE="$NAMESPACE/$IMAGE_NAME:$VERSION"
else
    REMOTE_IMAGE="$REGISTRY_URL/$NAMESPACE/$IMAGE_NAME:$VERSION"
fi

log_info "准备推送镜像到: $REMOTE_IMAGE"

# 检查本地镜像是否存在
if ! docker image inspect "$IMAGE_NAME:$VERSION" &> /dev/null; then
    log_error "本地镜像 $IMAGE_NAME:$VERSION 不存在"
    log_info "请先运行以下命令构建镜像:"
    echo "  ./build.sh build"
    exit 1
fi

# 检查 Docker 是否运行
if ! docker info &> /dev/null; then
    log_error "Docker 未运行，请先启动 Docker"
    exit 1
fi

# 检查是否已登录
log_info "检查登录状态..."
if [[ "$REGISTRY" == "dockerhub" ]]; then
    if ! docker info | grep -q "Username"; then
        log_warn "未登录 Docker Hub，请先登录:"
        echo "  docker login"
        exit 1
    fi
else
    # 提示用户登录（如果需要）
    log_info "如果尚未登录 $REGISTRY 镜像仓库，请先登录:"
    case $REGISTRY in
        "aliyun")
            echo "  docker login --username=your-username $LOGIN_SERVER"
            ;;
        "tencent")
            echo "  docker login $LOGIN_SERVER --username=your-username"
            ;;
        "huawei")
            echo "  docker login -u region@ak -p sk $LOGIN_SERVER"
            ;;
        "netease")
            echo "  docker login $LOGIN_SERVER"
            ;;
    esac
    echo ""
    read -p "是否已完成登录？(y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "请先完成登录后重试"
        exit 1
    fi
fi

# 标记镜像
log_info "标记镜像..."
docker tag "$IMAGE_NAME:$VERSION" "$REMOTE_IMAGE" || {
    log_error "镜像标记失败"
    exit 1
}

# 推送镜像
log_info "推送镜像到远程仓库..."
log_info "这可能需要几分钟时间，请耐心等待..."

if docker push "$REMOTE_IMAGE"; then
    log_info "✅ 镜像推送成功！"
    echo ""
    echo "=============================================="
    log_info "镜像信息:"
    echo "  仓库: $REGISTRY"
    echo "  镜像: $REMOTE_IMAGE"
    echo "  版本: $VERSION"
    echo ""
    log_info "拉取命令:"
    echo "  docker pull $REMOTE_IMAGE"
    echo ""
    log_info "运行命令:"
    echo "  docker run -it --name buildroot-env \\"
    echo "    -v \$(pwd)/buildroot:/workspace/buildroot \\"
    echo "    -v \$(pwd)/output:/workspace/output \\"
    echo "    $REMOTE_IMAGE"
    echo ""
    log_info "用户信息:"
    echo "  用户名: builduser"
    echo "  密码: 123456"
    echo "  权限: sudo 权限"
    echo "=============================================="
else
    log_error "镜像推送失败"
    log_info "可能的原因:"
    echo "  1. 网络连接问题"
    echo "  2. 未登录或登录信息过期"
    echo "  3. 命名空间或仓库不存在"
    echo "  4. 权限不足"
    exit 1
fi

# 清理本地标记的镜像（可选）
read -p "是否删除本地标记的镜像 $REMOTE_IMAGE？(y/N) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker rmi "$REMOTE_IMAGE" &> /dev/null || true
    log_info "本地标记镜像已清理"
fi

log_info "操作完成！"