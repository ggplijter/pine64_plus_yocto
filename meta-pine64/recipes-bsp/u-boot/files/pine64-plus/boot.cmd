# Pine64+ boot script, based on meta-sunxi's aarch64 boot.cmd
# Fix: fall back to the DTB in the root of the boot partition,
# since U-Boot's fdtfile points to allwinner/<name>.dtb
rootdev=mmcblk0p2
if itest.b *0x28 == 0x02 ; then
        echo "U-boot loaded from eMMC or secondary SD"
        rootdev=mmcblk1p2
fi
setenv bootargs console=${console} console=tty1 root=/dev/${rootdev} rootwait panic=10 cma=256M ${extra}
load mmc 0:1 ${fdt_addr_r} ${fdtfile} || load mmc 0:1 ${fdt_addr_r} sun50i-a64-pine64-plus.dtb
load mmc 0:1 ${kernel_addr_r} Image
booti ${kernel_addr_r} - ${fdt_addr_r}
