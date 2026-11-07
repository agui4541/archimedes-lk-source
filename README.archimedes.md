# Archimedes engineering LK port

This tree adds `archimedes_eng` on top of the public MT6761 LK source. It is an isolated source port; the upstream `k61v1_64_bsp` target is left unchanged.

## Device-specific source added

- `dev/lcm/otm8019a_boe_wvga/` is the LK build of the OTM8019A 480x800 panel driver copied from the current Archimedes kernel source. The LK driver keeps the kernel initialization tables, 2-lane DSI sync-pulse mode, 480x800 timing, and `otm8019a_boe_wvga` name.
- `dev/lcm/mt65xx_lcm_list.c` registers that driver when `OTM8019A_BOE_WVGA` is selected.
- `project/archimedes_eng.mk` selects MT6761, the OTM8019A panel, and the engineering security/fastboot feature set.
- `target/archimedes_eng/` is the target-specific copy used by that project.

## Reproducible build

From the repository root on the Linux build host:

```sh
TARGET_BUILD_VARIANT=eng JOBS=24 tools/build_archimedes_eng.sh
```

The script builds a native host `zpipe` from `dev/logo/tool/libz/zpipe.c` when the old checked-in 32-bit helper cannot run. This prevents the recurring `libz.so.1`/zlib loader failure. Set `BOOTLOADER_OUT` to select another output directory.

The output is compile-only. It is not a device flash instruction. The exact engineering `logo.bin` remains a separate 8 MiB artifact; the repository still contains only the public `hd720` logo source.

## Intentionally unchanged

- `platform/common/boot/boot_opt.c` is unmodified. Its third `bootopt` token remains the LK kernel-bit selector used by this device.
- The public K61 security libraries and signing flow are not replaced with guessed values.
- USB fallback `FASTBOOT_DEVNAME` is retained until a binary-confirmed engineering value is recovered; with the security/unlock configuration it is not emitted in the candidate image.

The target is therefore a reproducible, auditable LK source candidate, not a claim that every proprietary Xiaomi/MTK board blob has been reconstructed.

## Engineering-panel timing evidence

The extracted engineering LK OTM8019 table matches this port entry-for-entry after normalizing the old one-byte delay/end markers. Its disassembled get_params() writes PLL_CLOCK=188; this source uses 188 for LK. The Android kernel driver remains a separate runtime component and is intentionally unchanged at its validated value.

## Main DTB decision

The extracted engineering `lk.bin` has no `lk_main_dtb` loader strings and no FDT magic. The public MT6761 source tree nevertheless enabled `LK_MAIN_DTB_BUILT_IN` and appended `main_dtb_header.bin`, whose body identifies itself as an MT6580 DTB. For `archimedes_eng` and `archimedes_64`, the MT6761 rule now disables that loader and the build rule keeps `lk.img` equal to the plain MTK-header image. This avoids emitting a board-mismatched DTB. The flash payload is the 1 MiB padded `lk-bin.img`; no device flash has been performed.

The build helper also emits `build-archimedes_eng/lk.bin` and `lk2.bin` as exactly 1 MiB copies padded from `lk-bin.img`. Do not use the ELF `lk` file as a flash payload.
