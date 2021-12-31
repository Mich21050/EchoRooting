#!/bin/sh

# This script reloads the WiFi driver module

stop modules-atheros || :
sleep 1
start modules-atheros || :
