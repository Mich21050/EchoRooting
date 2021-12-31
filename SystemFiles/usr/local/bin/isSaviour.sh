#!/bin/sh

if (. /etc/ota_version && [ "$IS_SAVIOUR_OF_THE_UNIVERSE" = 'Y' ]) >/dev/null 2>&1; then
  echo '1'
  exit 0
fi

echo '0'
exit 0
