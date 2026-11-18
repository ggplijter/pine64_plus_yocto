cp -L build/tmp/deploy/images/pine64-plus/core-image-base-pine64-plus.rootfs.wic.gz /mnt/d/
cd /mnt/d && gunzip -f core-image-base-pine64-plus.rootfs.wic.gz
mv -f core-image-base-pine64-plus.rootfs.wic pine64-yocto.img

cd ~/yocto/pine64
