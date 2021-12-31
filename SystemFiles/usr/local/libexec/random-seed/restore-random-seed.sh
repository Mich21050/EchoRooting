#!/bin/bash
# Copyright (c) 2014 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# PROPRIETARY/CONFIDENTIAL
#
# Use is subject to license terms.

# See man page for random(4), which documents /dev/random and /dev/urandom

LIBEXECDIR=/usr/local/libexec/random-seed
POOLFILE=/proc/sys/kernel/random/poolsize
SEEDFILE=/var/local/random-seed

if [ ! -f $SEEDFILE ] ; then
    $LIBEXECDIR/initialize-random-seed.sh
fi

if [ ! -f $SEEDFILE ] ; then
    exit 1
fi

# ask kernel for size of entropy pool
if [ -r $POOLFILE ] ; then
    BYTES=$(cat $POOLFILE)
else
    BYTES=4096
fi

cat $SEEDFILE > /dev/urandom
dd if=/dev/urandom of=$SEEDFILE count=1 bs=$BYTES
