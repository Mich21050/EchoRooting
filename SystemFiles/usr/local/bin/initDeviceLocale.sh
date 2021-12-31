#!/bin/bash

# Copyright (c) 2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# PROPRIETARY/CONFIDENTIAL
# Use is subject to license terms.

# Script for setting device locale and default server end points based on IDME locale
#

LOCALE_DEFAULT="en-US"
STAGE_DEFAULT="prod"
REALM_DEFAULT="USAmazon"

IDME_LOCALE_KEY="mfg.locale"
DEVICE_LOCALE_KEY="device.locale"

ALEXA_ENDPOINT_KEY="url.alexa"
COMPANIONAPP_ENDPOINT_KEY="url.companionapp"

# Get device locale from IDME mfg.locale
# @return device locale, E.g. "en-US"
getBootLocale()
{
    BOOT_LOCALE=$(doppler-idme --key ${IDME_LOCALE_KEY} || true)
    if [ -z "${BOOT_LOCALE}" ]
    then
        logger -t system -p local4.info "W initDeviceLocale::getBootLocaleFailedUsingDefault"
        BOOT_LOCALE="${LOCALE_DEFAULT}"
    fi
    echo ${BOOT_LOCALE}
}

# initiate device.locale setting based on IDME locale setting
initDeviceLocale()
{
    DEVICE_LOCALE=$(get-dynconf-value ${DEVICE_LOCALE_KEY} || true)
    if [ -z "${DEVICE_LOCALE}" ]; then
        DEVICE_LOCALE=$(getBootLocale)
        logger -t system -p local4.info "I initDeviceLocale::initDeviceLocale(${DEVICE_LOCALE})"
        set-dynconf-value "${DEVICE_LOCALE_KEY}" "${DEVICE_LOCALE}"
    fi
}

# initiate OOBE registration and alexa end point based on dynconfig device.locale setting
# @param ENDPOINT_KEY key of the end point in dynconfig db, "url.alexa" or "url.companionapp"
initEndPointByLocale ()
{
    # "url.alexa" or "url.companionapp"
    ENDPOINT_KEY=$1
    ENDPOINT_URL=$(get-dynconf-value ${ENDPOINT_KEY} || true)
    if [ -z "${ENDPOINT_URL}" ]; then
        # first boot, set default URL based on locale
        DEVICE_LOCALE=$(get-dynconf-value ${DEVICE_LOCALE_KEY} || true)
        if [ -z "${DEVICE_LOCALE}" ]; then
            logger -t system -p local4.info "W initDeviceLocale::getDynconfLocaleFailedSetDefault"
            DEVICE_LOCALE=${LOCALE_DEFAULT}
        fi
        # E.g. DB [url.alexa.en-US] = url.alexa.prod.USAmazon
        ENDPOINT_STAGE_REALM=$(get-dynconf-value "${ENDPOINT_KEY}.$DEVICE_LOCALE" || true)
        if [ -z "${ENDPOINT_STAGE_REALM}" ]; then
            logger -t system -p local4.info "W initDeviceLocale::(${ENDPOINT_KEY}StageRealm)Failed"
            ENDPOINT_STAGE_REALM="${ENDPOINT_KEY}.${STAGE_DEFAULT}.${REALM_DEFAULT}"
            logger -t system -p local4.info "W initDeviceLocale::useDefault($ENDPOINT_STAGE_REALM}"
        fi
        ENDPOINT_URL=$(get-dynconf-value ${ENDPOINT_STAGE_REALM} || true)
        if [ -z "${ENDPOINT_URL}" ]; then
            logger -t system -p local4.info "E initDeviceLocale::endPointFailed(${ENDPOINT_KEY})"
        else
            logger -t system -p local4.info "I initDeviceLocale::setEndPoint(${ENDPOINT_KEY})"
            set-dynconf-value "${ENDPOINT_KEY}" "${ENDPOINT_URL}"
        fi
    fi
}

$(initDeviceLocale)
$(initEndPointByLocale ${ALEXA_ENDPOINT_KEY})
$(initEndPointByLocale ${COMPANIONAPP_ENDPOINT_KEY})

