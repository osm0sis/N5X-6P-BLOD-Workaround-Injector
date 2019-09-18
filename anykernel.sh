# AnyKernel3 Ramdisk Mod Script
# osm0sis @ xda-developers

## AnyKernel setup
# begin properties
properties() { '
kernel.string=N5X/6P BLOD Workaround Injector Add-on
do.devicecheck=1
do.modules=0
do.cleanup=1
do.cleanuponabort=1
device.name1=bullhead
device.name2=angler
'; } # end properties

# shell variables
block=/dev/block/platform/soc.0/f9824900.sdhci/by-name/boot;
is_slot_device=0;
ramdisk_compression=auto;


## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. tools/ak3-core.sh;


## AnyKernel boot install

ui_print " ";
ui_print "Patching boot partition...";

dump_boot;

# fix cmdline options
patch_cmdline "boot_cpus" "boot_cpus=0-3";
patch_cmdline "maxcpus" "maxcpus=4";

# fix cpuset in init.<device>.rc from Stock ramdisk
target=`getprop ro.hardware`;
replace_line init.$target.rc "write /dev/cpuset/foreground/cpus" "    write /dev/cpuset/foreground/cpus 0-3";
replace_line init.$target.rc "write /dev/cpuset/foreground/boost/cpus" "    write /dev/cpuset/foreground/boost/cpus 0-3";
replace_line init.$target.rc "write /dev/cpuset/background/cpus" "    write /dev/cpuset/background/cpus 3";
replace_line init.$target.rc "write /dev/cpuset/system-background/cpus" "    write /dev/cpuset/system-background/cpus 2-3";
replace_line init.$target.rc "write /dev/cpuset/top-app/cpus" "    write /dev/cpuset/top-app/cpus 0-3";

# fix additional possible cpusets from custom kernel ramdisks
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

