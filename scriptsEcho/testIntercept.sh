#!/bin/bash


while true
do
	dbus-monitor --system --profile "interface='com.doppler.ledd',member='setPatternStr'" |
	while read -r line; do
    		echo $line | grep setPatternStr && bash sendLed.sh off; sleep 1
	done
done
