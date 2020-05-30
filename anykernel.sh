# AnyKernel3 Ramdisk Mod Script
# osm0sis @ xda-developers

## AnyKernel setup
# begin properties
properties() { '
kernel.string=N5X/6P BLOD Workaround Injector Add-on
do.devicecheck=1
do.modules=0
do.systemless=0
do.cleanup=1
do.cleanuponabort=1
device.name1=bullhead
device.name2=angler
'; } # end properties

# shell variables
block=/dev/block/platform/soc.0/f9824900.sdhci/by-name/boot;
is_slot_device=0;
ramdisk_compression=auto;
no_block_display=1;


## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. tools/ak3-core.sh;


## AnyKernel boot install

ui_print " ";
ui_print "Patching boot partition...";

split_boot;

# fix cmdline options
patch_cmdline "boot_cpus" "boot_cpus=0-3";
patch_cmdline "maxcpus" "maxcpus=4";

# only attempt to unpack boot ramdisk if it is not SAR or 2SI
target=`getprop ro.hardware`;
if $bin/magiskboot cpio $split_img/ramdisk.cpio "exists init.$target.rc" 2>/dev/null; then
  has_ramdisk=1;
  unpack_ramdisk;
else
  flash_boot;
fi;

# fix cpusets in init.<device>.rc from AOSP (ramdisk or SAR) root
if [ ! "$has_ramdisk" ]; then
  ui_print "Patching system partition...";
  mount -o rw,remount -t auto /system_root;
  mount -o rw,remount -t auto /system;
  mount -o rw,remount -t auto /vendor;
  cd /system_root;
fi;
replace_line init.$target.rc "write /dev/cpuset/foreground/cpus" "    write /dev/cpuset/foreground/cpus 0-3";
replace_line init.$target.rc "write /dev/cpuset/foreground/boost/cpus" "    write /dev/cpuset/foreground/boost/cpus 0-3";
replace_line init.$target.rc "write /dev/cpuset/background/cpus" "    write /dev/cpuset/background/cpus 3";
replace_line init.$target.rc "write /dev/cpuset/system-background/cpus" "    write /dev/cpuset/system-background/cpus 2-3";
replace_line init.$target.rc "write /dev/cpuset/top-app/cpus" "    write /dev/cpuset/top-app/cpus 0-3";

# fix cpu onlines in init.<device>.power.sh from Treblized ROMs' (system and/or vendor) bin
if [ ! "$has_ramdisk" ]; then
  for i in /system /vendor; do
    if [ -e $i/bin/init.$target.power.sh ]; then
      test "$i" == "/vendor" && ui_print "Patching vendor partition...";
      replace_line $i/bin/init.$target.power.sh "write /sys/devices/system/cpu/cpu4/online 1" "write /sys/devices/system/cpu/cpu4/online 0";
      replace_line $i/bin/init.$target.power.sh "write /sys/devices/system/cpu/cpu5/online 1" "write /sys/devices/system/cpu/cpu5/online 0";
      replace_line $i/bin/init.$target.power.sh "write /sys/devices/system/cpu/cpu6/online 1" "write /sys/devices/system/cpu/cpu6/online 0";
      replace_line $i/bin/init.$target.power.sh "write /sys/devices/system/cpu/cpu7/online 1" "write /sys/devices/system/cpu/cpu7/online 0";
    fi;
  done;
  mount -o ro,remount -t auto /vendor;
  mount -o ro,remount -t auto /system;
  mount -o ro,remount -t auto /system_root;
fi;

# fix additional possible cpusets in init.*.rc from custom kernel ramdisks
if [ "$has_ramdisk" ]; then
  for i in $(ls init.*.rc); do
    replace_line $i "write /dev/cpuset/foreground/cpus 0-" "    write /dev/cpuset/foreground/cpus 0-3";
    replace_line $i "write /dev/cpuset/foreground/boost/cpus 0-" "    write /dev/cpuset/foreground/boost/cpus 0-3";
    replace_line $i "write /dev/cpuset/background/cpus 0-" "    write /dev/cpuset/background/cpus 3";
    replace_line $i "write /dev/cpuset/system-background/cpus 0-" "    write /dev/cpuset/system-background/cpus 2-3";

    replace_line $i "write /dev/cpuset/foreground/cpus 0-2,4-" "    write /dev/cpuset/foreground/cpus 0-3";
    replace_line $i "write /dev/cpuset/foreground/boost/cpus 4-" "    write /dev/cpuset/foreground/boost/cpus 0-3";
    replace_line $i "write /dev/cpuset/background/cpus 0-1" "    write /dev/cpuset/background/cpus 3";
    replace_line $i "write /dev/cpuset/system-background/cpus 0-2" "    write /dev/cpuset/system-background/cpus 2-3";
  done;
  write_boot;
fi;

## end boot install


# shell variables
block=/dev/block/platform/soc.0/f9824900.sdhci/by-name/recovery;
is_slot_device=0;
ramdisk_compression=auto;

# reset for recovery patching
reset_ak;


## AnyKernel recovery install

ui_print "Patching recovery partition...";

split_boot;

# fix cmdline options
patch_cmdline "boot_cpus" "boot_cpus=0-3";
patch_cmdline "maxcpus" "maxcpus=4";

flash_boot;

## end recovery install

