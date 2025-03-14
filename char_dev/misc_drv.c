#include "linux/device.h"
#include "linux/device/class.h"
#include "linux/export.h"
#include "linux/gfp_types.h"
#include "linux/miscdevice.h"
#include "linux/mutex.h"
#include "linux/pagemap.h"
#include "linux/printk.h"
#include "linux/slab.h"
#include <linux/module.h>
#include <linux/fs.h>
#include <linux/uaccess.h>
#include <linux/mm.h>
#include <linux/dma-mapping.h>

#define DEMO_DEV_NAME "demo_device"
#define STATUS_READY 0
#define STATUS_BUSY  1
#define IOCTL_MAGIC  'V'
#define IOCTL_SET_MODE _IOW(IOCTL_MAGIC, 1, int)
#define IOCTL_GET_STATUS _IOR(IOCTL_MAGIC, 1, int)

struct demo_device {
    char *dma_buffer;           // DMA模拟缓冲区
    size_t buffer_size;         // 缓冲区大小
    int mode;                   // 工作模式
    atomic_t status;            // 设备状态
    struct mutex lock;          // 互斥锁
};
static struct demo_device *vdev;

static int demo_open (struct inode *, struct file *);
static int demo_release (struct inode *, struct file *);
// static int demo_mmap (struct file *, struct vm_area_struct *);
// static long demo_ioctl (struct file *, unsigned int, unsigned long);

static int demo_open (struct inode * inode, struct file * filp)
{
    printk("demo open\n");
    if (!try_module_get (THIS_MODULE))
    {
        return -EBUSY;
    }

    atomic_set(&vdev->status, STATUS_BUSY);

    filp->private_data = vdev;
    return 0;
}

static int demo_release (struct inode * inode, struct file * filp)
{
    printk("demo release\n");
    module_put (THIS_MODULE);
    atomic_set(&vdev->status, STATUS_READY);
    return 0;
}

static ssize_t demo_read (struct file *filp, char __user *buf, size_t count, loff_t *pos)
{
    struct demo_device *dev = (struct demo_device *)filp->private_data;
    int ret = 0;
    printk("demo_read pos %lld\n",*pos);
    mutex_lock (&dev->lock);

    if (*pos >= dev->buffer_size)
    {
    ret = 0;
    goto out;
    }

    if (*pos + count > dev->buffer_size)
    {
        count = dev->buffer_size - *pos;
    }

    if (copy_to_user(buf, dev->dma_buffer + *pos, count))
    {
        ret = -EFAULT;
        goto out;
    }

    *pos += count;
    ret = count;

out:
    mutex_unlock (&dev->lock);
    return ret;
}

static ssize_t demo_write (struct file *filp, const char __user * buf, size_t count, loff_t *pos)
{
    struct demo_device *dev = (struct demo_device *)filp->private_data;
    int ret = 0;

    printk("demo_write pos %lld\n",*pos);

    mutex_lock (&dev->lock);

    if (*pos >= dev->buffer_size)
    {
        ret = -ENOSPC;
        goto out;
    }

    if (*pos + count > dev->buffer_size)
    {
        count = dev->buffer_size - *pos;
    }

    if (copy_from_user(dev->dma_buffer + *pos, buf, count))
    {
        ret = -EFAULT;
        goto out;
    }
    *pos += count;
    ret = count;
out:
    mutex_unlock(&dev->lock);
    return ret;
}

static long demo_ioctl (struct file *filp, unsigned int cmd, unsigned long arg)
{
    struct demo_device *dev = filp->private_data;
    int tmp;
    int ret = 0;

    switch (cmd)
    {
        case IOCTL_SET_MODE:
            if (copy_from_user(&tmp, (int __user *)arg, sizeof(int)))
            {
                return -EFAULT;
            }
            dev->mode = tmp;
            break;
        case IOCTL_GET_STATUS:
            tmp = atomic_read(&dev->status);
            if (copy_to_user((int __user *)arg, &tmp, sizeof(int)))
            {
                return -EFAULT;
            }
            break;
        default:
            printk("Not support cmd 0x%x\n", cmd);
            ret = -ENOTTY;
    }
    return ret;

}

static struct file_operations demo_fops = {
    .open = demo_open,
    .release = demo_release,
    .read = demo_read,
    .write = demo_write,
    .unlocked_ioctl = demo_ioctl,
    .owner = THIS_MODULE,
};

static struct miscdevice demo_device = {
    .minor = MISC_DYNAMIC_MINOR,
    .name = DEMO_DEV_NAME,
    .fops = &demo_fops,
    .mode = 0666,
};


static int __init demo_init(void)
{
    int ret = 0;
    printk("demo init\n");

    vdev = (struct demo_device *)kmalloc (sizeof(struct demo_device), GFP_KERNEL);
    if (!vdev)
        return -ENOMEM;

    vdev->buffer_size = 8*1024;

    vdev->dma_buffer = (char *)kmalloc (vdev->buffer_size, GFP_KERNEL);
    if (!vdev->dma_buffer)
    {
        ret = -ENOMEM;
        goto free_dev;
    }

    mutex_init(&vdev->lock);
    atomic_set(&vdev->status, STATUS_READY);
    vdev->mode = 0;

    ret = misc_register (&demo_device);
    if (ret < 0)
    {
        printk("misc_register err, %d\n", ret);
        ret = -EIO;
        goto free_buf;
    }


free_buf:
    kfree(vdev->dma_buffer);

free_dev:
    kfree(vdev);

    return ret;
}

static void __exit demo_exit(void)
{
    misc_deregister (&demo_device);
    kfree (vdev->dma_buffer);
    kfree (vdev);
    printk("demo exit\n");
}

module_init(demo_init)
module_exit(demo_exit)
MODULE_LICENSE("GPL");

