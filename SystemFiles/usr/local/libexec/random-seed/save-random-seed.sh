#!/bin/bash
# Copyright (c) 2014 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# PROPRIETARY/CONFIDENTIAL
#
# Use is subject to license terms.

# See man page for random(4), which documents /dev/random and /dev/urandom

POOLFILE=/proc/sys/kernel/random/poolsize
SEEDFILE=/var/local/random-seed

touch $SEEDFILE
chmod 0600 $SEEDFILE

# ask kernel for size of entropy pool
if [ -r $POOLFILE ] ; then
    BYTES=$(cat $POOLFILE)
else
    BYTES=4096
fi

dd if=/dev/urandom of=$SEEDFILE count=1 bs=$BYTES
