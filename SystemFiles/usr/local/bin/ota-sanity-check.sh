#!/bin/sh
# Sanity check script  - Run after OTA installation is complete
#  as part of the finalization step

LOGGER ()
{
logger -p local4.err -t "OTA: E ota-update-sanity:check:" $@;
}

# Check that sh alternative is installed for bash
grep -q "bash" /var/lib/opkg/alternatives/sh
BASH_RESULT=$?
if [ $BASH_RESULT -ne 0 ]; then
    echo "bash sh alternative not installed" | LOGGER
    exit 1
fi

exit 0
