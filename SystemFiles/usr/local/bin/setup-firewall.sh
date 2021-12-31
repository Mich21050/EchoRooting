#!/bin/bash

IPTABLES=/usr/sbin/iptables
DEBUG_RULES_HOOK=/etc/default/debug-firewall-rules.txt
ENABLEIDC=/media/card/enableIDC
CONNECT2MAC=/connect2mac
GET_DYN_CONF=/usr/local/bin/get-dynconf-value
COMPANION_APP_TCPTUNNEL_PORT_CONF_NAME=url.companionapp.tcptunnel.port
COMPANION_APP_TCPTUNNEL_PORT_DEFAULT=443

LOGGER() { logger -p local4.info -t "system: I firewall:setup:" $@; }

if [ ! -x $IPTABLES ]; then
    echo "$IPTABLES... not found"
    exit 1
fi

get_companion_app_tcptunnel_port() {

    local port=$(${GET_DYN_CONF} ${COMPANION_APP_TCPTUNNEL_PORT_CONF_NAME})
    if [ "${port}" == "" ]; then
        port=${COMPANION_APP_TCPTUNNEL_PORT_DEFAULT}
    fi

    print "Companion App TCPTunnel Port:${port}"
    echo -n "${port}"
}

# Add default firewall settings here
default_firewall_setup () {
    LOGGER "Setting up default firewall settings"
    $IPTABLES --flush

    # Default policy for all chains: DROP
    $IPTABLES -P INPUT DROP
    $IPTABLES -P OUTPUT DROP
    $IPTABLES -P FORWARD DROP

    # Accept RELATED,ESTABLISHED connections on wlan0 (device initiated)
    $IPTABLES -A INPUT -i wlan0 -p tcp -m state --state RELATED,ESTABLISHED -j ACCEPT
    $IPTABLES -A INPUT -i wlan0 -p udp -m state --state ESTABLISHED -j ACCEPT

    # Spotify Connect login server.
    $IPTABLES -A INPUT -i wlan0 -p tcp -m tcp --dport 4070 -j ACCEPT

    # Whatify Connect login server.
    $IPTABLES -A INPUT -i wlan0 -p tcp -m tcp --dport 4071 -j ACCEPT

    # CMB. Allow packets on port 5000
    $IPTABLES -A INPUT -i wlan0 -p udp --dport 5000 -j ACCEPT

    # SIP Calling support
    $IPTABLES -A INPUT -i wlan0 -p udp --dport 16384:32767 -j ACCEPT
    $IPTABLES -A INPUT -i wlan0 -p tcp --dport 16384:32767 -j ACCEPT

    # TPH traffic on wlan0. TPH/phd listens on port 40317
    $IPTABLES -A INPUT -i wlan0 -p tcp -m tcp --dport 40317 -j ACCEPT
    $IPTABLES -A INPUT -i wlan0 -p udp --dport 40317 --sport 40317 -j ACCEPT
    $IPTABLES -A INPUT -i wlan0 -p udp --dport 40317 --sport 49317 -j ACCEPT
    $IPTABLES -A INPUT -i wlan0 -p udp --dport 40317 --sport 33434 -j ACCEPT

    # Whole Home Audio traffic on wlan0.  The whad listens on:
    # udp port 55442 for audio distribution
    # tcp port 55442 for audio distribution
    # tcp port 55443 for control plane behavior
    # udp port 55444 for timestamp exchange
    # udp port 55445 for local network device discovery.
    $IPTABLES -A INPUT -i wlan0 -p udp --dport 55442 -j ACCEPT
    $IPTABLES -A INPUT -i wlan0 -p tcp -m tcp --dport 55442:55443 -j ACCEPT
    $IPTABLES -A INPUT -i wlan0 -p udp --dport 55444:55445 -j ACCEPT

    # UPnP:
    # allow traffic on Dst Port 1900 which are UPnP advertisements and Bye Bye
    # Allow traffic on Dst Port 50000; these pkts are SSDP search results
    # SSDP search queries are sent with Src Port 50000
    $IPTABLES -A INPUT -i wlan0  -p udp --dport 1900 -j ACCEPT
    $IPTABLES -A INPUT -i wlan0  -p udp --dport 50000 -j ACCEPT

    # mDNS: Avahi Publish of Spotify Connect service.
    $IPTABLES -A INPUT -i wlan0  -p udp --dport 5353 -j ACCEPT

    # ICMP:
    if [ -e $ENABLEIDC ]; then
        # AMPED Internal Only: Allow responses to all connections
        $IPTABLES -A INPUT -i "$P2PIF" -p icmp -j ACCEPT
    else
        # Allow only responses to local connections
        $IPTABLES -A INPUT -p icmp -m state --state RELATED,ESTABLISHED -j ACCEPT
    fi

    # AMPED External only
    if [ -f $CONNECT2MAC ]; then
        # AMPED External Only: Allow connections to port 40040
        $IPTABLES -A INPUT -i wlan0 -p tcp --dport 40040 -j ACCEPT
    fi

    # Add rules for internal debugging use
    [ -f $DEBUG_RULES_HOOK ] && . $DEBUG_RULES_HOOK

    # Allow all outgoing traffic on wlan0
    $IPTABLES -A OUTPUT -o wlan0 -j ACCEPT

    # Accept all on the loopback interface
    $IPTABLES -A INPUT -i lo -j ACCEPT
    $IPTABLES -A OUTPUT -o lo -j ACCEPT
}

# Firewall settings for P2P interface
# @param $1 P2P Interface name
# @param $2 OOBE Server IP address
p2p_firewall_start () {
    if [ $# -lt 2 ]; then
        LOGGER "Invalid argument on start p2p firewall"
        exit 1
    fi

    P2PIF=$1
    OOBEIP=$2

    LOGGER "Setting up P2P firewall settings on $1"

    COMPANION_APP_TCPTUNNEL_PORT=$(get_companion_app_tcptunnel_port)

    # Setup ip tables to reject all non-essential traffic
    # Redirect all DNS traffic to ourselves. This is necessary when the client device
    # has a static DNS address configured
    $IPTABLES -t nat -A PREROUTING -i "$P2PIF" -p udp --dport 53 -j DNAT --to ${OOBEIP}
    # ACCEPT all DNS traffic
    $IPTABLES -A INPUT -i "$P2PIF" -p udp --dport 53 -j ACCEPT
    # ACCEPT all DHCP traffic
    $IPTABLES -A INPUT -i "$P2PIF" -p udp --dport 67:68 --sport 67:68 -j ACCEPT
    # ACCEPT all incoming OOBE webserver traffic
    $IPTABLES -A INPUT -i "$P2PIF" -p tcp --dport 8080 -j ACCEPT
    $IPTABLES -A INPUT -i "$P2PIF" -p tcp --dport ${COMPANION_APP_TCPTUNNEL_PORT} -j ACCEPT

    # Allow all outgoing traffic
    $IPTABLES -A OUTPUT -o "$P2PIF" -j ACCEPT

    # AMPED Internal Only: Allow SSH incoming traffic to service Amped App
    if [ -e $ENABLEIDC ]; then
        $IPTABLES -A INPUT -i "$P2PIF" -p tcp --dport 22 -j ACCEPT
    fi
}

# Firewall settings for P2P interface
# @param $1 P2P Interface name
# @param $2 OOBE Server IP address
p2p_firewall_stop () {
    if [ $# -lt 2 ]; then
        LOGGER "Invalid argument on start p2p firewall"
        exit 1
    fi

    P2PIF=$1
    OOBEIP=$2

    LOGGER "Disabling P2P firewall settings on $1"

    COMPANION_APP_TCPTUNNEL_PORT=$(get_companion_app_tcptunnel_port)

    # Delete all rules setup by p2p_firewall_start
    # Delete DNS redirection
    $IPTABLES -t nat -D PREROUTING -i "$P2PIF" -p udp --dport 53 -j DNAT --to ${OOBEIP}
    # Delete ACCEPT all DNS traffic
    $IPTABLES -D INPUT -i "$P2PIF" -p udp --dport 53 -j ACCEPT
    # Delete ACCEPT all DHCP traffic
    $IPTABLES -D INPUT -i "$P2PIF" -p udp --dport 67:68 --sport 67:68 -j ACCEPT
    # Delete ACCEPT all incoming OOBE webserver traffic
    $IPTABLES -D INPUT -i "$P2PIF" -p tcp --dport 8080 -j ACCEPT
    $IPTABLES -D INPUT -i "$P2PIF" -p tcp --dport ${COMPANION_APP_TCPTUNNEL_PORT} -j ACCEPT

    # Delete Allow all outgoing traffic
    $IPTABLES -D OUTPUT -o "$P2PIF" -j ACCEPT

    # AMPED Internal Only:
    if [ -e $ENABLEIDC ]; then
        #  Delete Allow all incoming traffic
        $IPTABLES -D INPUT -i "$P2PIF" -p tcp --dport 22 -j ACCEPT
        # Delete ICMP Allow on P2P
        $IPTABLES -D INPUT -i "$P2PIF" -p icmp -j ACCEPT
        # ICMP Default: Allow only responses to local connections
        $IPTABLES -A INPUT -p icmp -m state --state RELATED,ESTABLISHED -j ACCEPT
    fi
}

# Firewall settings for NAT, to support captive portal authentication
# via companion app.
nat_firewall_start () {
    if [ $# -lt 1 ]; then
        LOGGER "Invalid argument on start nat firewall"
        exit 1
    fi

    IP=$1

    LOGGER "Enabling IP forwarding and NAT for $1"

    # Enable IP forwarding.
    echo 1 > /proc/sys/net/ipv4/ip_forward

    # Add rules for forwarding and NAT-ing traffic for the companion
    # app IP if necessary.
    $IPTABLES -C FORWARD -p tcp -s ${IP} -i p2p-+ -o wlan0 -j ACCEPT

    if [ $? -ne 0 ]; then
        # Forward TCP traffic coming in the P2P interface and heading out
        # the wlan0 interface, and reverse traffic related to connections
        # initiated by the host on the P2P interface.
        $IPTABLES -A FORWARD -p tcp -s $IP -i p2p-+ -o wlan0 -j ACCEPT
        $IPTABLES -A FORWARD -p tcp -m state --state RELATED,ESTABLISHED -j ACCEPT

        # Masquerade all NAT traffic.
        $IPTABLES -t nat -I POSTROUTING -o wlan0 -j MASQUERADE
    fi
}

# Firewall settings for NAT, to support captive portal authentication
# via companion app.
nat_firewall_stop () {
    LOGGER "Disabling IP forwarding and NAT"

    # Disable IP forwarding.
    echo 0 > /proc/sys/net/ipv4/ip_forward

    # Delete all forwarding traffic accept rules.
    $IPTABLES -F FORWARD

    # Delete NAT masquerade rule.
    $IPTABLES -t nat -D POSTROUTING -o wlan0 -j MASQUERADE
}

start_setup_firewall () {

    case "$1" in
        default)
            default_firewall_setup
            ;;
        p2p)
            shift
            p2p_firewall_start "$@"
            ;;
        nat)
            shift
            nat_firewall_start "$@"
            ;;
        *)
            exit 1
            ;;
    esac
}

stop_setup_firewall () {

    case "$1" in
        p2p)
            shift
            p2p_firewall_stop "$@"
            nat_firewall_stop
            ;;
        nat)
            shift
            nat_firewall_stop
            ;;
        *)
            exit 1
            ;;
    esac
}

case "$1" in
    start)
        if [ "$2" ]
        then
            shift
            # Setup any specific settings
            start_setup_firewall "$@"
            exit 0
        fi
        ;;
    stop)
        if [ "$2" ]
        then
            shift
            # Stop any specific settings
            stop_setup_firewall "$@"
            exit 0
        fi
        ;;
    *)
        exit 1
        ;;
esac

exit 1
