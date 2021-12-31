#!/bin/sh

DEFAULT_DEVICE_LOCALE="en-US"
DEFAULT_WAKEWORD="ALEXA"
ASRD_COMMON_PATH="/usr/local/data/models/keyword"

DEVICE_TYPE_PANCAKE="AKNO1N0KSFN8L"
DEVICE_TYPE_DOPPLER="AB72C64C86AW2"
DEVICE_TYPE_DEFAULT="${DEVICE_TYPE_DOPPLER}"

DEVICE_LOCALE="$(get-dynconf-value device.locale)"
DYN_CONFIG="$(get-dynconf-value asrd.model)"

## Figure out whether Doppler or Pancake
DEVICE_TYPE_IDME=$(doppler-idme | grep devicetype)
if [ -z "${DEVICE_TYPE_IDME}" ]
then
    logger -t system -p local4.info "W updateAsrdDynConfig.sh::getDeviceTypeFailedUsingDefault"
    DEVICE_TYPE_IDME="${DEVICE_TYPE_DEFAULT}"
fi

if [[ "${DEVICE_TYPE_IDME}" == *"${DEVICE_TYPE_DOPPLER}" ]]
then
    logger -t system -p local4.info "I updateAsrdDynConfig.sh::Doppler"
    ASRD_COMMON_PATH="$ASRD_COMMON_PATH/doppler"
elif [[ "${DEVICE_TYPE_IDME}" == *"${DEVICE_TYPE_PANCAKE}" ]]
then
    logger -t system -p local4.info "I updateAsrdDynConfig.sh::Pancake"
    ASRD_COMMON_PATH="$ASRD_COMMON_PATH/pancake"
else
    logger -t system -p local4.info "W updateAsrdDynConfig.sh::Using Default"
    ASRD_COMMON_PATH="$ASRD_COMMON_PATH/doppler"
fi

# The dyn config value has before this change pointed to pryon.config,
# which is being deprecated. We need it to point it to pryon.manifest.
if [[ $DYN_CONFIG == *"pryon.config" ]]
then
    DYN_CONFIG=${DYN_CONFIG%pryon.config*}
    DYN_CONFIG="${DYN_CONFIG}pryon.manifest"
    set-dynconf-value asrd.model $DYN_CONFIG
fi

if [ -z "$DYN_CONFIG" ] || [ ! -e "$DYN_CONFIG" ]
then
    logger -t system -p local4.info "I updateAsrdDynConfig.sh Dyn config is being updated"

    # The first time we move over the models to locale specific directories,
    # the dyn config path set from before is not going to have any contents.
    # But, when we move over to the locale specific folders, we should try
    # and set the same WW model.
    OLD_WWMODEL=${DYN_CONFIG%/*}
    OLD_WWMODEL=${OLD_WWMODEL##*/}

    if [ -z "$DEVICE_LOCALE" ]
    then
        logger -t system -p local4.info "I updateAsrdDynConfig.sh device.locale is not set for this device"
        DEVICE_LOCALE="${DEFAULT_DEVICE_LOCALE}"
    fi

    ASRD_LOCALE_PATH="$ASRD_COMMON_PATH/$DEVICE_LOCALE"

    ## Check if there is a default file in the path constructed till now
    if [ ! -z "$OLD_WWMODEL" ]
    then
        WAKEWORD="$OLD_WWMODEL"
    elif [ -e "$ASRD_LOCALE_PATH/default" ]
    then
        ## Read the default file and set the WAKEWORD
        WAKEWORD="$(cat $ASRD_LOCALE_PATH/default)"
    else
        logger -t system -p local4.info "I updateAsrdDynConfig.sh old setting or default WW model for locale doesn't exist"
        WAKEWORD="$DEFAULT_WAKEWORD"
    fi

    if [ -e "$ASRD_LOCALE_PATH/$WAKEWORD/pryon.manifest" ]
    then
         set-dynconf-value asrd.model $ASRD_LOCALE_PATH/$WAKEWORD/pryon.manifest
    elif [ -e "$ASRD_COMMON_PATH/$DEFAULT_DEVICE_LOCALE/$WAKEWORD/pryon.manifest" ]
    then
         set-dynconf-value asrd.model $ASRD_COMMON_PATH/$DEFAULT_DEVICE_LOCALE/$WAKEWORD/pryon.manifest
    else
         set-dynconf-value asrd.model $ASRD_COMMON_PATH/$DEFAULT_WAKEWORD/pryon.manifest
    fi

else
    logger -t system -p local4.info "I updateAsrdDynConfig.sh Dyn config stays the same"
fi
logger -t system -p local4.info "I updateAsrdDynConfig.sh Dyn config:$DYN_CONFIG"
exit 0
