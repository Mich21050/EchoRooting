#!/bin/sh

#
# Handle incoming button events from buttond. As lipc-daemon can only pass the same event to a
# single script, this script will further handle specific button events.
#

# Button events have 4 input parameters, event, lipc source, button name, and button state.
if [ $# -ne 4 ]; then
    exit 1
fi

# Uber short press buttons should be sent to controld to emulate the wakeword.
if [ "$3" = "uber" -a $4 -eq 3 ]; then
    /usr/local/bin/lipc-set-prop com.doppler.controld -s wakeWordFired yes

# Factory reset button down should be sent to factory-reset.
elif [ "$3" = "factoryReset" -a $4 -eq 1 ]; then
    /usr/local/bin/factory-reset

fi
