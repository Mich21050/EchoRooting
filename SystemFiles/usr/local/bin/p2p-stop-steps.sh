#! /bin/sh
# Script to take down the p2p-interface

CONFIG=/etc/default/p2pd
source $CONFIG

disable_wifi_manual_mode ()
{
    # Disable manual mode for cmd
    $LIPC_SET com.lab126.cmd enableManualMode 0
    # Disable manual mode for wifid
    $LIPC_SET com.lab126.wifid cmConnMode ALWAYS
    # Send request to wifid to connect to any network
    $LIPC_SET com.lab126.wifid cmConnect ""
}

bring_it_down()
{
    # Disable manual mode here, since stopping OOBE can take some time
    disable_wifi_manual_mode
    # Take down the OOBE webserver
    /sbin/stop $OOBED_UPSTART_JOB
    # Disable manual mode again, in case oobe re-enabled it before shutdown
    disable_wifi_manual_mode

    if [ -z "$P2PINTERFACE" ]
    then
        echo "The interface you are trying to take down does not exist"
        exit 1;
    else
        $WPACLI -i p2p0 p2p_group_remove $P2PINTERFACE
        $IW dev p2p0 set power_save on
    fi

    # Restore ip tables
    $FIREWALL_SETUP stop p2p $P2PINTERFACE $OOBE_SERVER_ADDR
}

bring_it_down
exit 0
