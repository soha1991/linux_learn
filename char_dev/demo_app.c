#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <sys/ioctl.h>

#define DEVICE_PATH "/dev/demo_device"

// 如果驱动支持 ioctl，定义命令（需与内核驱动一致）
#define IOCTL_MAGIC  'V'
#define IOCTL_SET_MODE _IOW(IOCTL_MAGIC, 1, int)
#define IOCTL_GET_STATUS _IOR(IOCTL_MAGIC, 1, int)

int main() {
    int fd;
    char write_buf[100] = "Hello from userspace!";
    char read_buf[100] = {0};

    // 1. 打开设备文件
    fd = open(DEVICE_PATH, O_RDWR);
    if (fd < 0) {
        perror("Failed to open device");
        exit(EXIT_FAILURE);
    }
    printf("Device opened successfully.\n");

    // 2. 向设备写入数据
    ssize_t ret = write(fd, write_buf, strlen(write_buf));
    if (ret < 0) {
        perror("Write failed");
        close(fd);
        exit(EXIT_FAILURE);
    }
    close(fd);
    printf("Wrote %zd bytes: %s\n", ret, write_buf);

    fd = open(DEVICE_PATH, O_RDWR);
    if (fd < 0) {
        perror("Failed to open device");
        exit(EXIT_FAILURE);
    }
#if 1
    // 3. 从设备读取数据
    ret = read(fd, read_buf, sizeof(read_buf));
    if (ret < 0) {
        perror("Read failed");
        close(fd);
        exit(EXIT_FAILURE);
    }

    printf("Read %zd bytes: %s\n", ret, read_buf);

    // 4. 可选：测试 ioctl（如果驱动支持）
    int mode  = 1;
    if (ioctl(fd, IOCTL_SET_MODE, &mode) < 0) {
        perror("IOCTL failed");
    } else {
        printf("IOCTL SET MODE succeeded. Value: %d\n", mode);
    }

    int status;
    if (ioctl(fd, IOCTL_GET_STATUS, &status) < 0) {
        perror("IOCTL failed");
    } else {
        printf("IOCTL GET STATUS succeeded. Value: %d\n", status);
    }
#endif
    // 5. 关闭设备
    close(fd);
    return 0;
}