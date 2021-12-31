#!/bin/sh

print() {
    logger -p local0.info -t factory-reset.sh $1
}

print "Script triggered with parameters: $*"

# registrationChanged events have 5 parameters eventName, lipcSource, registration enum, statusCode, isCausedByRemoteTransfer.
if [ $# -ne 5 ]; then
	print "Unknown arguments list, ignoring factory-reset"
    exit 1
fi

OOBEEnabled=$(lipc-get-prop com.doppler.p2p APState)
print "OOBEEnabled value : $OOBEEnabled"

if [ "x$OOBEEnabled" = "x" -o -z "$OOBEEnabled" ]; then
	print "Unable to decide if OOBE is running, ignoring factory-reset"
    exit 1
fi

# authd will send a event registrationChanged with value 2 when the device is de-registered.
# do not factory reset the device when the device is in OOBE.
# do not factory reset the device when the device is undergoing remote transfer
if [ $3 -ne 2 ]; then
	print "Not de-registration, ignoring factory-reset"
elif [ $OOBEEnabled -ne 0 ]; then
	print "OOBE inprogress, ignoring factory-reset"
elif [ $5 -eq 1 ]; then
	print "Device is undergoing remote transfer, ignoring factory-reset"
else
	# print "Device de-registered by user. Starting factory-reset"
	# /usr/local/bin/factory-reset
	print "Factory-reset on device de-registration is disabled for this build, ignoring factory-reset"
fi