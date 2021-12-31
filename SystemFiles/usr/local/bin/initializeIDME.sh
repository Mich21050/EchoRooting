#!/bin/sh

#
# initializeIDME.sh
#
# Copyright (c) 2012 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# PROPRIETARY/CONFIDENTIAL
#
# Use is subject to license terms.
#

#
# Initialize IDME.
#
$(/usr/local/bin/doppler-idme --initialize)

exit $?

