#!/bin/sh

# This script is written manually and is specific to how Bluez stores information about paired
# devices. Any change to BlueZ configuration or implementation would potentially impact this file
# and should be reviewed

SCONE_MAC_IDME_KEY=mfg.remotemac
SCONE_LINKKEY_IDME_KEY=mfg.remotelinkkey
DOPPLER_LINKKEY_INVALID_VALUE=none
DOPPLER_MAC_IDME_KEY=mfg.btmac

PREPAIRING_COMPLETE_FILE=/var/local/system/persist/factorypairingComplete
PREPAIRING_STATE_PENDING=pending
PREPAIRING_STATE_COMPLETE=complete

BLUEZ_DB_PATH=/var/local/lib/bluetooth
BTMD_DB_PATH=/var/local/btmd

SCONE_VENDOR_ID=1949
SCONE_PRODUCT_ID=0405

BLUEZ_DB_DID_VALUE=0001
BLUEZ_DB_CLASSES_VALUE=0x08050c
BLUEZ_DB_FEATURES_VALUE=FFFE2DFEDBFF7B83
BLUEZ_DB_MANUFACTURERS_VALUE="13 6 6974"
BLUEZ_DB_PROFILES_VALUE="00000002-4ea8-470e-92bf-0f1d90b4724e 00001101-0000-1000-8000-00805f9b34fb 00001124-0000-1000-8000-00805f9b34fb 00001200-0000-1000-8000-00805f9b34fb"
BLUEZ_DB_TRUSTS_VALUE="[all]"
BLUEZ_DB_EIR_VALUE=0109020A0409FF313934393034303503000000040D0C0508
BLUEZ_DB_SDP_VALUE_1="#00010000 36014A0900000A000100000900013503191124090004350D35061901000900113503190011090006350909656E09006A0901000900093508350619112409010009000D350F350D35061901000900133503190011090100252253746F6E65737472656574204F6E6520426C7565746F6F7468204B6579626F61726409020009010009020109011109020208800902030800090204280009020528000902063581357F0822257B05010906A101150025010B660007000BE2000C000B500007000BB4000C000BE9000C000BF10007000B580007000BCD000C000B89000C000B520007000B4F0007000BB3000C000BEA000C000B23020C000B510007000B40000C000B21020C00951175018102950775018103150025640B20000600950175088102C0090207350835060904090901000902082800090209280109020A280009020B09010009020D280109020E2800"
BLUEZ_DB_SDP_VALUE_2="#00010002 354D0900000A000100020900013503191101090004350C350319010035051900030802090006350909656E09006A090100090100251953657269616C20506F72742053657276657220506F72742032"
BLUEZ_DB_SDP_VALUE_3="#00010001 35330900000A0001000109000135031912000902000901030902010919490902020904050902030900010902042801090205090001"
BLUEZ_DB_LINKKEYS_VALUE="4 0"

create_db_classes ()
{
    echo "${SCONE_MAC} ${BLUEZ_DB_CLASSES_VALUE}" > ${BLUEZ_DB_PATH}/${DOPPLER_MAC}/classes
}

create_db_did ()
{
    echo "${SCONE_MAC} ${BLUEZ_DB_DID_VALUE} ${SCONE_VENDOR_ID} ${SCONE_PRODUCT_ID} ${BLUEZ_DB_DID_VALUE}" > ${BLUEZ_DB_PATH}/${DOPPLER_MAC}/did
}

create_db_features ()
{
    echo "${SCONE_MAC} ${BLUEZ_DB_FEATURES_VALUE}" > ${BLUEZ_DB_PATH}/${DOPPLER_MAC}/features
}

create_db_manufacturers ()
{
    echo "${SCONE_MAC} ${BLUEZ_DB_MANUFACTURERS_VALUE}" > ${BLUEZ_DB_PATH}/${DOPPLER_MAC}/manufacturers
}

create_db_profiles ()
{
    echo "${SCONE_MAC} ${BLUEZ_DB_PROFILES_VALUE}" > ${BLUEZ_DB_PATH}/${DOPPLER_MAC}/profiles
}

create_db_trusts ()
{
    echo "${SCONE_MAC} ${BLUEZ_DB_TRUSTS_VALUE}" > ${BLUEZ_DB_PATH}/${DOPPLER_MAC}/trusts
}

create_db_eir ()
{
    echo "${SCONE_MAC} ${BLUEZ_DB_EIR_VALUE}" > ${BLUEZ_DB_PATH}/${DOPPLER_MAC}/eir
}

create_db_names ()
{
    echo "${SCONE_MAC} " > ${BLUEZ_DB_PATH}/${DOPPLER_MAC}/names
}

create_db_sdp ()
{
    echo "${SCONE_MAC}${BLUEZ_DB_SDP_VALUE_1}" > ${BLUEZ_DB_PATH}/${DOPPLER_MAC}/sdp
    echo "${SCONE_MAC}${BLUEZ_DB_SDP_VALUE_2}" >> ${BLUEZ_DB_PATH}/${DOPPLER_MAC}/sdp
    echo "${SCONE_MAC}${BLUEZ_DB_SDP_VALUE_3}" >> ${BLUEZ_DB_PATH}/${DOPPLER_MAC}/sdp
}

create_db_linkkeys ()
{
    LINKKEY=$1
    echo "${SCONE_MAC} ${LINKKEY} ${BLUEZ_DB_LINKKEYS_VALUE}" > ${BLUEZ_DB_PATH}/${DOPPLER_MAC}/linkkeys
}

create_bluez_db ()
{
    if [ ! -f ${BLUEZ_DB_PATH}/${DOPPLER_MAC} ]; then
        echo "Creating Bluez Database path" | LOGGER
        mkdir ${BLUEZ_DB_PATH}/${DOPPLER_MAC}
    fi

    create_db_classes
    create_db_did
    create_db_features
    create_db_manufacturers
    create_db_profiles
    create_db_trusts
    create_db_eir
    create_db_names
    create_db_sdp

    if [ "$1" != "" -a "$1" != "${DOPPLER_LINKKEY_INVALID_VALUE}" ]; then
    echo "Creating linkkkeys file" | LOGGER
    create_db_linkkeys $1
    else
    echo "Skipping creating linkkeys file" | LOGGER
    fi
}

cleanup_bluez_db ()
{
    rm -rf ${BLUEZ_DB_PATH}/${DOPPLER_MAC}/*
}

cleanup_btmd_db ()
{
    rm -rf ${BTMD_DB_PATH}/*
}

cleanup_bluetooth_db ()
{
    cleanup_btmd_db
    cleanup_bluez_db
}

LOGGER ()
{
logger -p local4.info -t "BTCS: I pre-pairing:setup:" $@;
}

# Check if the Doppler has previously completed factory pairing
if [ -f $PREPAIRING_COMPLETE_FILE ]; then
    read -r VALUE < $PREPAIRING_COMPLETE_FILE
    if [ "$VALUE" != "${PREPAIRING_STATE_COMPLETE}" ] && [ "$VALUE" != "${PREPAIRING_STATE_PENDING}" ]; then
        echo "Factory pairing has not been done before. Proceed with pre-pairing" | LOGGER
    else
        echo "Factory pairing is already complete. Abandon pre-pairing" | LOGGER
        exit 0
    fi
else
    # Prepairing complete file does not exist.
    echo "Proceed with pre-pairing" | LOGGER
fi

# Proceed with pre-pairing
# Read Doppler's BT Address and format it correctly
DOPPLER_MAC=`doppler-idme --key ${DOPPLER_MAC_IDME_KEY}`
if [ "${DOPPLER_MAC}" == "" ]; then
    echo "Doppler's BT MAC Address not found in IDME. Abandon pre-pairing" | LOGGER
    exit 1
fi

DOPPLER_MAC=`echo ${DOPPLER_MAC:0:2}:${DOPPLER_MAC:2:2}:${DOPPLER_MAC:4:2}:${DOPPLER_MAC:6:2}:${DOPPLER_MAC:8:2}:${DOPPLER_MAC:10:2}`
DOPPLER_MAC_DISPLAY=${DOPPLER_MAC}
if (. /etc/ota_version && [ "$BUILD_VARIANT" = "release" ]) >/dev/null 2>&1; then
  # In release builds, only display redacted MAC address
  DOPPLER_MAC_DISPLAY=`echo XX:XX:XX:XX:${DOPPLER_MAC:12:5}`
fi

# Read the Scone's BT address and format it correctly
SCONE_MAC=`doppler-idme --key ${SCONE_MAC_IDME_KEY}`
if [ "${SCONE_MAC}" == "" ]; then
    echo "Scone's BT MAC Address not found in IDME. Abandon pre-pairing" | LOGGER
    exit 0
fi

SCONE_MAC=`echo ${SCONE_MAC:0:2}:${SCONE_MAC:2:2}:${SCONE_MAC:4:2}:${SCONE_MAC:6:2}:${SCONE_MAC:8:2}:${SCONE_MAC:10:2}`
SCONE_MAC_DISPLAY=${SCONE_MAC}
if (. /etc/ota_version && [ "$BUILD_VARIANT" = "release" ]) >/dev/null 2>&1; then
  # In release builds, only display redacted Scone address
  SCONE_MAC_DISPLAY=`echo XX:XX:XX:XX:${SCONE_MAC:12:5}`
fi
echo "Scone's BT Address is ${SCONE_MAC_DISPLAY}" | LOGGER

# Read the linkkey to be used for factory pairing
SCONE_LINKKEY=`doppler-idme --key ${SCONE_LINKKEY_IDME_KEY}`

if [ "${SCONE_LINKKEY}" == "" ]; then
    echo "Scone's linkkey is not found in IDME" | LOGGER
else
    echo "Scone's linkkey is ${SCONE_LINKKEY}" | LOGGER
fi

# Cleanup any existing bluetooth databases
echo "Cleaning up BlueZ's database" | LOGGER
cleanup_bluetooth_db

# Create Bluez Database
create_bluez_db "${SCONE_LINKKEY}"

# Mark that factory pairing is now pending on BTMD's actions
echo "Pre-pairing completed on Bluez successfully" | LOGGER
echo -n "${PREPAIRING_STATE_PENDING}" > ${PREPAIRING_COMPLETE_FILE}
