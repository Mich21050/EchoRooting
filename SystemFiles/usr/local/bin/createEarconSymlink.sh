#!/bin/sh

# alarmd and earconPlayer assumes earcon in this folder
EARCON_SYMLINK="/var/local/earcon"
# earcon file for different regions are organized under this base directory
EARCON_PATH_BASE="/usr/local/share/earcon"
DEVICE_TYPE_PANCAKE="AKNO1N0KSFN8L"
DEVICE_TYPE_DOPPLER="AB72C64C86AW2"

DEVICE_DOPPLER="doppler"
DEVICE_PANCAKE="pancake"
DEVICE_DEFAULT=${DEVICE_DOPPLER}

DEVICE_LOCALE_KEY="device.locale"
LOCALE_DEFAULT="en-US"

# Get device type
# @return "doppler" or "pancake"
getDeviceType()
{
    DEVICE_TYPE_IDME=$(doppler-idme --key mfg.devicetype)
    if [ -z "${DEVICE_TYPE_IDME}" ]
    then
        logger -t system -p local4.info "E createEarconSymlink::getDeviceTypeFailed"
    fi

    if [[ "${DEVICE_TYPE_IDME}" == "${DEVICE_TYPE_DOPPLER}" ]]
    then
        logger -t system -p local4.info "I createEarconSymlink::Doppler"
        DEVICE_TYPE=${DEVICE_DOPPLER}
    elif [[ "${DEVICE_TYPE_IDME}" == "${DEVICE_TYPE_PANCAKE}" ]]
    then
        logger -t system -p local4.info "I createEarconSymlink::Pancake"
        DEVICE_TYPE=${DEVICE_PANCAKE}
    else
        logger -t system -p local4.info "W createEarconSymlink::unknownDeviceTypeUsingDefault"
        DEVICE_TYPE=${DEVICE_DEFAULT}
    fi
    echo ${DEVICE_TYPE}
}

# Get device locale from dynconfig db
# @return device locale, E.g. "en-US"
getDeviceLocale()
{
    BOOT_LOCALE=$(get-dynconf-value ${DEVICE_LOCALE_KEY} || true)
    if [ -z "${BOOT_LOCALE}" ]
    then
        logger -t system -p local4.info "W createEarconSymlink::getDeviceLocaleFailedUsingDefault"
        BOOT_LOCALE="${LOCALE_DEFAULT}"
    fi
    echo ${BOOT_LOCALE}
}

# Create/replace earcon symlink
# @param deviceLocale (E.g. "en-US")
# @return 0 for success 1 for failure
createSymLink()
{
    DEVICE_LOCALE=$1
    DEVICE_TYPE=$(getDeviceType)
    EARCON_PATH="${EARCON_PATH_BASE}/${DEVICE_TYPE}/${DEVICE_LOCALE}"
    if [ ! -e "${EARCON_PATH}" ]
    then
        logger -t system -p local4.info "E createEarconSymlink::invalidEarconPath(${EARCON_PATH})"
        return 1
    else
        # delete symlink if it exists
        if [ -h "${EARCON_SYMLINK}" ]
        then
            logger -t system -p local4.info "I createEarconSymlink::deleteExistingSymlink"
            rm ${EARCON_SYMLINK}
        fi

        logger -t system -p local4.info "I createEarconSymlink::createNewSymLink(${EARCON_PATH})"
        ln -s "${EARCON_PATH}" "${EARCON_SYMLINK}"
        if [ $? -eq 0 ]
        then
            logger -t system -p local4.info "I createEarconSymlink::createNewSymLinkSucceeded"
            return 0
        else
            logger -t system -p local4.info "E createEarconSymlink::createNewSymLinkFailed"
            return 1
        fi
    fi
}

if [ "$#" -eq 0 ]
then
    logger -t system -p local4.info "I createEarconSymlink::initialization"
    # verify if target file exists
    if [ ! -e "${EARCON_SYMLINK}" ]
    then
        DEVICE_LOCALE=$(getDeviceLocale)
        logger -t system -p local4.info "I createEarconSymlink::${DEVICE_LOCALE}"
        exit $(createSymLink $DEVICE_LOCALE)
    else
        logger -t system -p local4.info "I createEarconSymlink::FileExists"
        exit 0
    fi
elif [ "$#" -eq 1 ]
then
    logger -t system -p local4.info "I createEarconSymlink::switchLocale($1)"
    exit $(createSymLink $1)
fi

