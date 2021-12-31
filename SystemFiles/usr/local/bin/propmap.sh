#!/bin/sh
# Copyright (c) 2013 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# PROPRIETARY/CONFIDENTIAL
#
# Use is subject to license terms.
#
# Helper script to manage named read/write properties on Doppler.

FAILURE=1
SUCCESS=0
PROPDIR=/var/local/system/persist

test $# -gt 0 || exit $FAILURE

PROPNAME=$1
PROPFILE=${PROPDIR}/${PROPNAME}

# make sure directory exists
if [ ! -d $PROPDIR ]; then
    mkdir -p $PROPDIR
fi

# make mapped properties begin as empty strings
if [ ! -f $PROPFILE ]; then
    /bin/touch $PROPFILE
fi

if [ $# -gt 1 ]; then
    # we are writing to this property
    PROPVALUE=$2
    echo -n $PROPVALUE > $PROPFILE
fi

cat $PROPFILE

exit $SUCCESS
