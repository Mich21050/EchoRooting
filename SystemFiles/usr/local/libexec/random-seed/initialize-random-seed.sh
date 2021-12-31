#!/bin/bash
# Copyright (c) 2014 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# PROPRIETARY/CONFIDENTIAL
#
# Use is subject to license terms.

# This should *only* execute on first boot to initialize the kernel PRNG
# It initializes the seed file by hashing the IDME partition
#
# see man page for random(4), which documents /dev/random and /dev/urandom

POOLFILE=/proc/sys/kernel/random/poolsize
SEEDFILE=/var/local/random-seed

# No, seriously: *only* on first boot
if [ -f $SEEDFILE ] ; then
    exit 0
fi

# ask kernel for size of entropy pool
if [ -r $POOLFILE ] ; then
    BYTES=$(cat $POOLFILE)
else
    BYTES=4096
fi

# Calculate how many sha512sum are needed to cover the pool
ITERS=$(($BYTES * 8 / 512))

# generate lots of hex bytes by chaining the sha512sum's
#
# While this is not a *random* seed, it is at least unique to each
# device and unlikely to be predicted.  The IDME partition includes
# the device serial number, mac addresses, calibration data, some
# device secrets, and filesystem timestamps. Thus, even after a
# factory reset the output of this hash is expected to change.
HEX=$(dd if=/dev/disk/by-partlabel/idme bs=1M 2>/dev/null | sha512sum | awk '{print $1}')
N=0
while [ $N -lt $ITERS ] ; do
    NEWHEX=$(echo -n "$HEX" | sha512sum | awk '{print $1}')
    HEX="${HEX}${NEWHEX}"
    N=$(($N + 1))
done

# create file and set perms
touch $SEEDFILE
chmod 0600 $SEEDFILE

# Trim to proper size, convert to binary, write to file
HEX=${HEX:0:$(($BYTES * 2))}
printf $(echo $HEX | sed 's/\(..\)/\\x\1/g') > $SEEDFILE
