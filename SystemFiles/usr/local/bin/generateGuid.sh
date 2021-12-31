#!/bin/sh

#
# generateGUID.sh
#
# Copyright (c) 2012 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# PROPRIETARY/CONFIDENTIAL
#
# Use is subject to license terms.
#

GUID_PATH="/var/local/system/guid"

mkdir -p $(dirname $GUID_PATH)

#
# Generates a GUID for use when device identification is to remain anonymous.
#
# The GUID is only generated if the file does not already exist.
#
if [ ! -f $GUID_PATH ]; then
    logger -t system -p local4.info "I initscripts:generateGUID::Generating guid"
    GUID=$(dd if=/dev/urandom bs=32 count=1 2>/dev/null | md5sum | cut -d ' ' -f 1)
    echo $GUID > $GUID_PATH
fi

exit 0

