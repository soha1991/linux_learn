# ARM64 Buildroot 交叉编译环境使用指南

本文档介绍如何使用 Docker 在 macOS 上搭建 ARM64 Buildroot 交叉编译环境。

## 📋 前置条件

- macOS 系统
- Docker Desktop for Mac 已安装并运行
- 至少 8GB 可用内存
- 至少 20GB 可用磁盘空间

## 🚀 快速开始

### 1. 构建 Docker 镜像

```bash
# 构建镜像
docker build -t buildroot-arm64:latest .

# 或使用 docker-compose
docker-compose build
```

### 2. 准备 Buildroot 源码

```bash
# 克隆 Buildroot 仓库
git clone https://github.com/buildroot/buildroot.git
cd buildroot
git checkout 2024.02.x  # 选择稳定版本
```

### 3. 运行容器

#### 方式一：使用 Docker 命令

```bash
docker run -it \
  -v $(pwd)/buildroot:/workspace/buildroot \
  -v $(pwd)/output:/workspace/output \
  --name buildroot-arm64-builder \
  buildroot-arm64:latest
```

#### 方式二：使用 docker-compose

```bash
# 启动服务
docker-compose up -d

# 进入容器
docker-compose exec buildroot-arm64 bash
```

## 🔧 使用说明

### 配置 Buildroot

```bash
# 进入容器后，使用内置脚本
~/build.sh menuconfig

# 或手动配置
cd /workspace/buildroot
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- qemu_aarch64_virt_defconfig
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- menuconfig
```

### 常用配置选项

在 `menuconfig` 中设置以下选项：

1. **Target options**
   - Target Architecture: AArch64 (little endian)
   - Target Architecture Variant: cortex-a53 (或其他 ARM64 变体)

2. **Toolchain**
   - Toolchain type: External toolchain
   - Toolchain: Custom toolchain
   - Toolchain prefix: aarch64-linux-gnu

3. **System configuration**
   - System hostname: 设置主机名
   - Root password: 设置 root 密码

### 开始构建

```bash
# 使用内置脚本构建
~/build.sh build

# 或手动构建
cd /workspace/buildroot
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)
```

## 📁 目录结构

```
/workspace/
├── buildroot/          # Buildroot 源码
├── output/            # 构建输出目录
└── buildroot/
    ├── output/        # Buildroot 默认输出
    │   ├── images/    # 生成的镜像文件
    │   ├── target/    # 目标文件系统
    │   └── host/      # 主机工具链
    └── dl/           # 下载缓存
```

## 🔍 常用命令

```bash
# 查看可用的默认配置
make list-defconfigs | grep aarch64

# 清理构建
make clean

# 完全清理（包括配置）
make distclean

# 查看帮助
make help

# 构建特定包
make <package-name>

# 重新构建特定包
make <package-name>-rebuild
```

## 🛠️ 高级使用

### 自定义配置

1. 创建自定义配置文件：
```bash
cp configs/qemu_aarch64_virt_defconfig configs/my_custom_defconfig
```

2. 修改配置后使用：
```bash
make my_custom_defconfig
```

### 添加自定义包

1. 在 `package/` 目录下创建自定义包目录
2. 编写 `Config.in` 和 `*.mk` 文件
3. 在 `package/Config.in` 中包含自定义包

### 使用外部树

```bash
# 设置外部树路径
export BR2_EXTERNAL=/path/to/external/tree
make <custom-defconfig>
```

## 📊 性能优化

### 启用 ccache

```bash
# 在 menuconfig 中启用
Build options -> Enable compiler cache (ccache)
```

### 并行构建

```bash
# 使用所有 CPU 核心
make -j$(nproc)

# 限制并行任务数
make -j4
```

## 🐛 常见问题

### 1. 权限问题

```bash
# 修复输出目录权限
sudo chown -R $(whoami):$(whoami) output/
```

### 2. 磁盘空间不足

```bash
# 清理下载缓存
rm -rf dl/*

# 清理构建输出
make clean
```

### 3. 网络问题

```bash
# 设置代理 (如需要)
export http_proxy=http://proxy.example.com:8080
export https_proxy=http://proxy.example.com:8080
```

## 📝 输出文件

构建完成后，在 `output/images/` 目录中可以找到：

- `rootfs.tar`: 根文件系统 tar 包
- `Image`: Linux 内核镜像
- `*.dtb`: 设备树文件 (如适用)
- `rootfs.ext2`: ext2 文件系统镜像

## 🔗 相关资源

- [Buildroot 官方文档](https://buildroot.org/documentation.html)
- [ARM64 架构指南](https://developer.arm.com/documentation)
- [Docker 官方文档](https://docs.docker.com/)

## 💡 提示

1. 首次构建可能需要较长时间，建议使用 ccache 加速后续构建
2. 建议定期备份 `.config` 文件
3. 使用 `make savedefconfig` 保存最小配置文件
4. 构建前确保有足够的磁盘空间 (建议 20GB+)

---

如有问题，请参考 Buildroot 官方文档或提交 issue。