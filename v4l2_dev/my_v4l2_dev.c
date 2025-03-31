#include "linux/export.h"
#include "linux/gfp_types.h"
#include "linux/printk.h"
#include "linux/slab.h"
#include "linux/string.h"
#include "media/v4l2-dev.h"
#include "media/v4l2-ioctl.h"
#include <linux/module.h>
#include <linux/init.h>
#include <linux/videodev2.h>
#include <media/v4l2-device.h>

struct my_v4l2_dev {
    struct v4l2_device v4l2_dev;
    struct video_device vdev;
};


static int my_open (struct file *filp);
static int my_release (struct file *filp);

static struct my_v4l2_dev *my_dev;
static struct v4l2_file_operations my_fops = {
    .owner = THIS_MODULE,
    .open = my_open,
    .release = my_release,
    .unlocked_ioctl = video_ioctl2,
};
static struct v4l2_ioctl_ops my_ioctl_ops = {
    // .vidioc_querycap =,
    // .vidioc_enum_fmt_vid_cap = ,
    // .vidioc_g_fmt_vid_cap,

};

static int __init my_v4l2_dev_init(void)
{
    int ret;

    my_dev = kmalloc(sizeof(struct my_v4l2_dev), GFP_KERNEL);
    if(my_dev == NULL)
    {
    pr_err("Alloc my dev err.\n");
    }

    pr_info("Initializing my V4L2 device\n");

    ret = v4l2_device_register(NULL, &my_dev->v4l2_dev);
    if (ret) {
        pr_err("Failed to register V4L2 device: %d\n", ret);
        return ret;
    }

    pr_info("Initializing my vidoe device\n");

    struct video_device *vdev = &my_dev->vdev;
    strscpy(vdev->name, "My V4L2 device", sizeof(vdev->name));
    vdev->v4l2_dev = &my_dev->v4l2_dev;
    vdev->fops = &my_fops;
    vdev->ioctl_ops = &my_ioctl_ops;
    vdev->release = ;
    vdev->device_caps = ;

    ret = video_register_device (vdev, VFL_TYPE_VIDEO, -1);
    if(ret < 0)
    {
    pr_err("Register video device err, %d\n", ret);
    return -ENODEV;
    }


    pr_info("V4L2 device registered successfully\n");
    return 0;
}

static void __exit my_v4l2_dev_exit(void)
{
    pr_info("Exiting my V4L2 device\n");
    video_unregister_device(&my_dev->vdev);
    v4l2_device_unregister(&my_dev->v4l2_dev);
    kfree(my_dev);
    pr_info("V4L2 device unregistered successfully\n");
}

module_init(my_v4l2_dev_init);
module_exit(my_v4l2_dev_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Your Name");
MODULE_DESCRIPTION("A simple V4L2 device example");