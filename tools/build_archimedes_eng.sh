#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
OUT=${BOOTLOADER_OUT:-/mnt/scsi1/work/lk-build-archimedes-eng}
HOST_TOOLS=${HOST_TOOLS:-$OUT/host-tools}
ZPIPE=${ZPIPE:-$HOST_TOOLS/zpipe}
JOBS=${JOBS:-24}
TARGET_BUILD_VARIANT=${TARGET_BUILD_VARIANT:-eng}
export TARGET_BUILD_VARIANT
mkdir -p "$HOST_TOOLS"
if [ ! -x "$ZPIPE" ]; then
    command -v gcc >/dev/null 2>&1 || { echo "gcc is required to build the native zpipe helper" >&2; exit 2; }
    gcc -O2 -Wno-unused-result "$ROOT/dev/logo/tool/libz/zpipe.c" -o "$ZPIPE" -lz
fi
[ -x "$ZPIPE" ] || { echo "native zpipe build failed: $ZPIPE" >&2; exit 2; }
make -C "$ROOT" archimedes_eng -j"$JOBS" TARGET_BUILD_VARIANT="$TARGET_BUILD_VARIANT" BOOTLOADER_OUT="$OUT" ZPIPE="$ZPIPE"

# The MTK flash payload is the plain header image. Keep an explicit 1 MiB
# payload pair so callers do not accidentally use the ELF or a DTB-appended
# audit image.
BUILD="$OUT/build-archimedes_eng"
[ -f "$BUILD/lk-bin.img" ] || { echo "missing plain LK image: $BUILD/lk-bin.img" >&2; exit 2; }
dd if="$BUILD/lk-bin.img" of="$BUILD/lk.bin" bs=1M conv=sync status=none
cp -f "$BUILD/lk.bin" "$BUILD/lk2.bin"
