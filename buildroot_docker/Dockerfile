# Dockerfile for ARM64 Buildroot Cross-Compilation
# Based on Ubuntu 22.04 LTS with ARM64 cross-compilation toolchain
# Supports both x86_64 and ARM64 (Apple Silicon) host platforms

FROM --platform=linux/amd64 ubuntu:22.04

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# 安装 sudo 和密码管理工具
RUN apt-get update && apt-get install -y sudo && \
    rm -rf /var/lib/apt/lists/*

# 创建工作用户并设置密码
RUN useradd -m -s /bin/bash builduser && \
    echo 'builduser:123456' | chpasswd && \
    usermod -aG sudo builduser && \
    echo "builduser ALL=(ALL) ALL" >> /etc/sudoers

# 设置默认用户密码提示
RUN echo "echo '默认用户: builduser, 密码: 123456'" >> /etc/motd

# 更新包管理器并安装基础依赖
RUN apt-get update && apt-get install -y \
    # 基础工具
    wget \
    curl \
    git \
    build-essential \
    vim \
    nano \
    unzip \
    file \
    bc \
    rsync \
    cpio \
    python3 \
    python3-pip \
    python3-dev \
    # M4 宏处理器
    m4 \
    # Buildroot 依赖
    libncurses5-dev \
    libncursesw5-dev \
    libtool \
    autoconf \
    automake \
    pkg-config \
    # 交叉编译工具链
    gcc-aarch64-linux-gnu \
    g++-aarch64-linux-gnu \
    libc6-dev-arm64-cross \
    # 其他必要工具
    bison \
    flex \
    gawk \
    texinfo \
    help2man \
    gperf \
    libtool-bin \
    libglib2.0-dev \
    libfdt-dev \
    libpixman-1-dev \
    zlib1g-dev \
    # 网络工具
    ca-certificates \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*

# 设置交叉编译环境变量
ENV CROSS_COMPILE=aarch64-linux-gnu-
ENV CC=aarch64-linux-gnu-gcc
ENV CXX=aarch64-linux-gnu-g++
ENV AR=aarch64-linux-gnu-ar
ENV STRIP=aarch64-linux-gnu-strip
ENV OBJCOPY=aarch64-linux-gnu-objcopy
ENV OBJDUMP=aarch64-linux-gnu-objdump
ENV RANLIB=aarch64-linux-gnu-ranlib

# 安装最新版本的 CMake (如果需要)
RUN wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | \
    gpg --dearmor - | \
    tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null && \
    apt-add-repository 'deb https://apt.kitware.com/ubuntu/ jammy main' && \
    apt-get update && \
    apt-get install -y cmake && \
    rm -rf /var/lib/apt/lists/*

# 创建工作目录
RUN mkdir -p /workspace/buildroot /workspace/output
WORKDIR /workspace

# 下载并设置 Buildroot (可选，也可以挂载外部目录)
# RUN git clone https://github.com/buildroot/buildroot.git buildroot && \
#     cd buildroot && \
#     git checkout 2024.02.x

# 设置权限
RUN chown -R builduser:builduser /workspace

# 切换到非 root 用户
USER builduser

# 设置 Git 配置 (可选)
RUN git config --global user.name "Build User" && \
    git config --global user.email "builduser@example.com"

# 创建一个便捷的构建脚本
RUN cat > /home/builduser/build.sh << 'EOF'
#!/bin/bash
set -e

echo "=== ARM64 Buildroot Build Environment ==="
echo "Cross Compile Prefix: $CROSS_COMPILE"
echo "CC: $CC"
echo "CXX: $CXX"
echo "Working Directory: $(pwd)"
echo "========================================"

# 检查 Buildroot 是否存在
if [ ! -d "buildroot" ]; then
    echo "Buildroot not found. Please mount your buildroot source or clone it."
    echo "Example: docker run -v /path/to/buildroot:/workspace/buildroot ..."
    exit 1
fi

cd buildroot

# 如果没有配置文件，创建一个基础的 ARM64 配置
if [ ! -f ".config" ]; then
    echo "Creating default ARM64 configuration..."
    make ARCH=arm64 CROSS_COMPILE=$CROSS_COMPILE qemu_aarch64_virt_defconfig
fi

# 显示菜单配置 (可选)
if [ "$1" = "menuconfig" ]; then
    make ARCH=arm64 CROSS_COMPILE=$CROSS_COMPILE menuconfig
elif [ "$1" = "build" ]; then
    echo "Starting build process..."
    make ARCH=arm64 CROSS_COMPILE=$CROSS_COMPILE -j$(nproc)
else
    echo "Usage: $0 [menuconfig|build]"
    echo "  menuconfig - Open build configuration menu"
    echo "  build      - Start the build process"
fi
EOF

RUN chmod +x /home/builduser/build.sh

# 设置容器启动时的默认命令
CMD ["/bin/bash"]

# 添加一些有用的别名
RUN echo 'alias ll="ls -la"' >> /home/builduser/.bashrc && \
    echo 'alias build="~/build.sh"' >> /home/builduser/.bashrc && \
    echo 'export PS1="\u@buildroot-arm64:\w\$ "' >> /home/builduser/.bashrc

# 暴露一些常用端口 (如果需要运行服务)
EXPOSE 8080 22

# 设置工作目录
WORKDIR /workspace

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD aarch64-linux-gnu-gcc --version || exit 1