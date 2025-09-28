#!/bin/bash

# ARM64 Buildroot 构建脚本
# 用于 macOS Docker 环境

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
PROJECT_NAME="buildroot-arm64"
DOCKER_IMAGE="buildroot-arm64:latest"
CONTAINER_NAME="buildroot-arm64-builder"
BUILDROOT_VERSION="2024.02.x"

# 函数定义
print_help() {
    echo -e "${BLUE}ARM64 Buildroot 构建脚本${NC}"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  build           构建 Docker 镜像"
    echo "  setup           设置 Buildroot 源码"
    echo "  run             运行构建容器"
    echo "  shell           进入容器 shell"
    echo "  push            推送镜像到远程仓库"
    echo "  clean           清理容器和镜像"
    echo "  logs            查看容器日志"
    echo "  help            显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 build        # 构建镜像"
    echo "  $0 setup        # 下载并设置 Buildroot"
    echo "  $0 run          # 启动构建环境"
    echo "  $0 push         # 推送镜像到远程仓库"
    echo ""
}

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装，请先安装 Docker Desktop for Mac"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        log_error "Docker 未运行，请启动 Docker Desktop"
        exit 1
    fi
}

build_image() {
    log_info "构建 Docker 镜像: $DOCKER_IMAGE (支持 Apple Silicon)"
    
    if [ ! -f "Dockerfile" ]; then
        log_error "Dockerfile 不存在，请确保在正确的目录中运行此脚本"
        exit 1
    fi
    
    # 检测当前平台
    PLATFORM="linux/amd64"
    if [[ $(uname -m) == "arm64" ]]; then
        log_info "检测到 Apple Silicon Mac，使用 Rosetta 2 模拟"
    fi
    
    docker build --platform $PLATFORM -t $DOCKER_IMAGE . || {
        log_error "镜像构建失败"
        exit 1
    }
    
    log_info "镜像构建完成"
}

setup_buildroot() {
    log_info "设置 Buildroot 源码"
    
    if [ -d "buildroot" ]; then
        log_warn "buildroot 目录已存在，是否重新克隆? (y/N)"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            rm -rf buildroot
        else
            log_info "使用现有的 buildroot 目录"
            return 0
        fi
    fi
    
    log_info "克隆 Buildroot 仓库 (版本: $BUILDROOT_VERSION)"
    git clone https://github.com/buildroot/buildroot.git || {
        log_error "克隆 Buildroot 仓库失败"
        exit 1
    }
    
    cd buildroot
    git checkout $BUILDROOT_VERSION || {
        log_error "检出版本 $BUILDROOT_VERSION 失败"
        exit 1
    }
    cd ..
    
    # 创建输出目录
    mkdir -p output
    
    log_info "Buildroot 设置完成"
}

run_container() {
    log_info "启动构建容器"
    
    # 检查镜像是否存在
    if ! docker image inspect $DOCKER_IMAGE &> /dev/null; then
        log_warn "镜像 $DOCKER_IMAGE 不存在，正在构建..."
        build_image
    fi
    
    # 检查 buildroot 目录
    if [ ! -d "buildroot" ]; then
        log_warn "buildroot 目录不存在，正在设置..."
        setup_buildroot
    fi
    
    # 停止并删除现有容器 (如果存在)
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_info "停止现有容器"
        docker stop $CONTAINER_NAME &> /dev/null || true
        docker rm $CONTAINER_NAME &> /dev/null || true
    fi
    
    # 运行新容器
    docker run -it \
        --platform linux/amd64 \
        --name $CONTAINER_NAME \
        -v "$(pwd)/buildroot:/workspace/buildroot" \
        -v "$(pwd)/output:/workspace/output" \
        -v "buildroot-dl:/workspace/buildroot/dl" \
        -v "buildroot-ccache:/home/builduser/.ccache" \
        -e "CROSS_COMPILE=aarch64-linux-gnu-" \
        -e "ARCH=arm64" \
        $DOCKER_IMAGE
}

enter_shell() {
    log_info "进入容器 shell"
    
    if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_error "容器 $CONTAINER_NAME 未运行"
        log_info "请先运行: $0 run"
        exit 1
    fi
    
    docker exec -it $CONTAINER_NAME /bin/bash
}

clean_up() {
    log_info "清理容器和镜像"
    
    # 停止并删除容器
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_info "删除容器 $CONTAINER_NAME"
        docker stop $CONTAINER_NAME &> /dev/null || true
        docker rm $CONTAINER_NAME &> /dev/null || true
    fi
    
    # 删除镜像
    if docker image inspect $DOCKER_IMAGE &> /dev/null; then
        log_warn "是否删除镜像 $DOCKER_IMAGE? (y/N)"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            docker rmi $DOCKER_IMAGE
            log_info "镜像已删除"
        fi
    fi
    
    # 清理卷
    log_warn "是否删除构建缓存卷? (y/N)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        docker volume rm buildroot-dl buildroot-ccache &> /dev/null || true
        log_info "缓存卷已删除"
    fi
}

show_logs() {
    if ! docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_error "容器 $CONTAINER_NAME 不存在"
        exit 1
    fi
    
    docker logs -f $CONTAINER_NAME
}

push_image() {
    log_info "推送镜像到远程仓库"
    
    if [ ! -f "push-image.sh" ]; then
        log_error "推送脚本不存在"
        exit 1
    fi
    
    ./push-image.sh "$2" "$3"
}

# 主函数
main() {
    # 检查参数
    if [ $# -eq 0 ]; then
        print_help
        exit 1
    fi
    
    # 检查 Docker
    check_docker
    
    # 处理命令
    case "$1" in
        build)
            build_image
            ;;
        setup)
            setup_buildroot
            ;;
        run)
            run_container
            ;;
        shell)
            enter_shell
            ;;
        push)
            push_image "$@"
            ;;
        clean)
            clean_up
            ;;
        logs)
            show_logs
            ;;
        help|--help|-h)
            print_help
            ;;
        *)
            log_error "未知选项: $1"
            print_help
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"