echo "setenv mmc_part 1:5" > /dev/ttyUSB0
sleep 1
echo "setenv root /dev/mmcblk1p5" > /dev/ttyUSB0
sleep 1
echo -e "setenv mmcargs 'setenv bootargs console=\${console} root=\${root} \${mount_type} rootfstype=ext3 rootwait \${config_extra}'" > /dev/ttyUSB0
sleep 1
echo "setenv mount_type rw" > /dev/ttyUSB0
sleep 1
echo "boot" > /dev/ttyUSB0
