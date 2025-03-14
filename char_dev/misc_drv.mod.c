#include <linux/module.h>
#define INCLUDE_VERMAGIC
#include <linux/build-salt.h>
#include <linux/elfnote-lto.h>
#include <linux/export-internal.h>
#include <linux/vermagic.h>
#include <linux/compiler.h>

#ifdef CONFIG_UNWINDER_ORC
#include <asm/orc_header.h>
ORC_HEADER;
#endif

BUILD_SALT;
BUILD_LTO_INFO;

MODULE_INFO(vermagic, VERMAGIC_STRING);
MODULE_INFO(name, KBUILD_MODNAME);

__visible struct module __this_module
__section(".gnu.linkonce.this_module") = {
	.name = KBUILD_MODNAME,
	.init = init_module,
#ifdef CONFIG_MODULE_UNLOAD
	.exit = cleanup_module,
#endif
	.arch = MODULE_ARCH_INIT,
};

#ifdef CONFIG_RETPOLINE
MODULE_INFO(retpoline, "Y");
#endif



static const struct modversion_info ____versions[]
__used __section("__versions") = {
	{ 0x122c3a7e, "_printk" },
	{ 0x16baa87d, "module_put" },
	{ 0x2851328b, "try_module_get" },
	{ 0xba09fa75, "kmalloc_caches" },
	{ 0x7ffe2937, "kmalloc_trace" },
	{ 0xcefb0c9f, "__mutex_init" },
	{ 0xca1c22eb, "misc_register" },
	{ 0x37a0cba, "kfree" },
	{ 0xa24c0027, "misc_deregister" },
	{ 0x4dfa8d4b, "mutex_lock" },
	{ 0x6cbbfc54, "__arch_copy_to_user" },
	{ 0x3213f038, "mutex_unlock" },
	{ 0x12a4e128, "__arch_copy_from_user" },
	{ 0xf0fdf6cb, "__stack_chk_fail" },
	{ 0xdcb764ad, "memset" },
	{ 0x1057439c, "module_layout" },
};

MODULE_INFO(depends, "");

