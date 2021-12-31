#! /bin/sh
# Script to bring up the p2p-interface

CONFIG=/etc/default/p2pd
source $CONFIG

DSN=`cat /proc/dsn`
let SERIAL_LENGTH=${#DSN}-3
SERIAL_DIGITS=${DSN:$SERIAL_LENGTH}
AP_SSID="Amazon-$SERIAL_DIGITS"

LOGGER ()
{
logger -p local4.err -t "P2PD: E p2p-start-steps:start_it_up:" $@;
}

if (source /etc/ota_version && [ "$IS_SAVIOUR_OF_THE_UNIVERSE" = 'Y' ]) >/dev/null 2>&1; then
    let SERIAL_LENGTH=${#DSN}-3
    SERIAL_DIGITS=${DSN:$SERIAL_LENGTH}
    AP_SSID="Amazon-$SERIAL_DIGITS"
    echo $AP_SSID | LOGGER
fi

start_it_up()
{
    echo "Bringing up the interface"
    if [ -z "$P2PINTERFACE" ]
    then
        # Bring up the OOBE webserver
        /sbin/start $OOBED_UPSTART_JOB
        if [ "$?" -ne "0" ]
        then
            echo "Unable to start OOBED server" | LOGGER
            exit 1
        fi

        # Always bring up p2p interface on 2.4GHz band
        $WPACLI -i p2p0 p2p_group_add freq=2 unsecured ssid=$AP_SSID
        if [ "$?" -ne "0" ]
        then
            echo "Unable to bring up the P2P interface" | LOGGER
            exit 1
        fi

        # Source config to update value of P2PINTERFACE.
        source $CONFIG

        # Setup ip tables to reject all non-essential traffic
        $FIREWALL_SETUP start p2p $P2PINTERFACE $OOBE_SERVER_ADDR
        if [ "$?" -ne "0" ]
        then
            # Stop P2P mode and return error
            $P2P_STOP_SCRIPT
            /sbin/stop $OOBED_UPSTART_JOB
            exit 1
        fi

        $IFCONFIG $P2PINTERFACE $OOBE_SERVER_ADDR up
        P2PNETMASK=`get-dynconf-value p2p.netmask || true`
        if [ -n "$P2PNETMASK" ]
        then
            $IFCONFIG $P2PINTERFACE netmask $P2PNETMASK
        fi
        # Disable power save on all p2p interfaces
        $IW dev p2p0 set power_save off
        $IW dev $P2PINTERFACE set power_save off

    else
        echo "Interface already up" | LOGGER
        exit 1;
    fi
}

start_it_up

exit 0
