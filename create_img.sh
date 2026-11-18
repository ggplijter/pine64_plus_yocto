#!/usr/bin/env bash
# Unpack the latest SD card image to a Windows drive for flashing.
#
# Usage:
#   ./create_img.sh              write /mnt/d/pine64-yocto.img
#   ./create_img.sh /mnt/e       write to another directory
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"

MACHINE=pine64-plus
IMAGE=core-image-base
DEPLOY=build/tmp/deploy/images/$MACHINE
SRC=$DEPLOY/$IMAGE-$MACHINE.rootfs.wic.gz
OUT_DIR=${1:-/mnt/d}
OUT=$OUT_DIR/pine64-yocto.img

if [ ! -e "$SRC" ]; then
    echo "Image not found: $SRC (has the build finished?)" >&2
    exit 1
fi
if [ ! -d "$OUT_DIR" ]; then
    echo "Output directory not found: $OUT_DIR" >&2
    exit 1
fi

echo "Source: $(readlink -f "$SRC")"
echo "Built:  $(date -r "$(readlink -f "$SRC")" '+%Y-%m-%d %H:%M')"

# Unpack to a temporary name first, so a failed run never leaves a broken image
gunzip -c "$SRC" > "$OUT.tmp"
mv -f "$OUT.tmp" "$OUT"

echo "Written: $OUT ($(du -h "$OUT" | cut -f1))"
echo "Flash with Win32DiskImager, balenaEtcher or Rufus: $(wslpath -w "$OUT" 2> /dev/null || echo "$OUT")"
