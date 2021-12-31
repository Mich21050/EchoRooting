#!/bin/bash

# Copyright (c) 2014 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# PROPRIETARY/CONFIDENTIAL
# Use is subject to license terms.

# Script for installing and merging new appreg.db's. Typically runs on boot by Upstart.
#
# Functions Include...
# - Detecting when appreg.db has been updated (due to an OTA) and merging it with the user's
#   database, preserving their settings.
# - Installing new appreg.db's in /var/local
# - Sanity checking user's appreg.db on boot
# - Migrates from old appreg symlinked from /etc to new appreg in /var/local

# register returns pragma check results in it's exit status. So we must run without -e
set +e

APPREG_BASE=/etc/appreg.db.base
APPREG_BASE_SHA=/var/local/appreg.db.base.sha256

# DB with user settable options which need to be merged add-or-ignore if they exist
APPREG_BASE_USER=/etc/appreg-settingsd.db.base
APPREG_BASE_USER_SHA=/var/local/appreg-settingsd.db.base.sha256

APPREG_USER=/var/local/appreg.db

die ()
{
    logE "$@"
    return
}

# Logging functions
logI ()
{
    logger -t system -p local4.info I initscripts:appreg-install::$1
}
logE ()
{
    logger -t system -p local4.error E initscripts:appreg-install::$1
}

# Function to remove the user's DB and hash
cleanUser ()
{
    logI "Removing $APPREG_USER, $APPREG_BASE_SHA, and $APPREG_BASE_USER_SHA"

    rm -f $APPREG_USER
    rm -f $APPREG_BASE_SHA
    rm -f $APPREG_BASE_USER_SHA
}

# Run an integrity check. If it fails, clear out the user DB so it can be replaced
runIntegrityCheck ()
{
    PRAGMA_MSG=$(register -v)
    PRAGMA_RES=$?
    if [ $PRAGMA_RES != 0 ]; then
        logE "$APPREG_USER pragma check failed! Error code $PRAGMA_RES ($PRAGMA_MSG)"

        # Later the script will discover the user db is missing and replace it
        logE "Existing user $APPREG_USER corrupt, restoring defaults"
        cleanUser
    fi
}

# Generate 1 SHA and save it
# Takes: path to DB file, path to SHA file
generateSha()
{
    sha256sum $1 > $2 || logE "Couldn't sha256 $1 to $2"
}

# Generate both SHA files
generateShas()
{
    generateSha $APPREG_BASE $APPREG_BASE_SHA
    generateSha $APPREG_BASE_USER $APPREG_BASE_USER_SHA
}

# Execute a merge between the specified database and the device database in /var/local. Use the
# specified mode.
# Takes: path to DB to merge from, merge mode flags
performMerge()
{
    local MERGE_MSG=$(register -$2 $1)
    local MERGE_RES=$?
    if [ $MERGE_RES != 0 ]; then
        logE "Merge failed! Error code ($MERGE_RES) ($MERGE_MSG)"
    fi

    return $MERGE_RES
}

# Update the given database if the SHA does not match
# Takes: path to DB file, path to SHA file, merge flags to use
updateIfChanged ()
{
    logI "Checking if $1 has been updated"

    # When sha256sum is run the first time, it outputs the hash and the path to the file
    # which was hashed. When the tool is run again with -c, it hashes that file and checks
    # if the hases match.
    sha256sum -cs $2
    local SHA_RES=$?

    if [ $SHA_RES != 0 ] && [ -f $1 ]; then
            # Appreg.db.base was updated, so merge with the user's
            logI "$1 was updated, starting merge process"

            # Actually perform the database merge, using the given flags
            performMerge $1 $3
            if [ $? != 0 ]; then
                # Make sure there is no user db at this point. The script will replace it with default
                cleanUser

            else
                # Grab a hash of the new base
                generateSha $1 $2

                logI "Merge complete"

                # Pragma check the new database
                runIntegrityCheck
            fi
    else
        logI "$1 not updated"
    fi
}


# Check if the user's appreg.db is a symlink. If so, remove it
logI "Checking if $APPREG_USER is a symlink"
if [ -L $APPREG_USER ]; then
    logI "$APPREG_USER was a symlink"

    cleanUser
fi

logI "Checking if $APPREG_USER is sane"
runIntegrityCheck

# Check if either appreg in /etc a new sha256.
# If either has been changed (which indicates an OTA) then the user's DB must be
# updated to include whatever new values may exist.

updateIfChanged $APPREG_BASE $APPREG_BASE_SHA "m"
updateIfChanged $APPREG_BASE_USER $APPREG_BASE_USER_SHA "im"

# Check if appreg exists
logI "Detecting if $APPREG_USER exists"
if [ ! -f $APPREG_USER ]; then
    # If not, copy from /etc
    logI "$APPREG_USER did not exist, installing from $APPREG_BASE and $APPREG_BASE_USER"

    cp -f $APPREG_BASE $APPREG_USER || die "Couldn't write $APPREG_BASE to $APPREG_USER!"

    # Merge in default user settings from settingsd. Ignore if they already exist
    performMerge $APPREG_BASE_USER "im"

    # Generate a hash of the base file for later comparison
    generateShas
fi

logI "$APPREG_USER Ready"

