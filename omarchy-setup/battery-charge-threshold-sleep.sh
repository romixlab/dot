#!/bin/sh
# systemd-sleep hook: macsmc-battery can drop charge_control_end_threshold
# back to 100 across suspend/resume, so reapply it on wake.
case "$1" in
  post)
    echo 80 > /sys/class/power_supply/macsmc-battery/charge_control_end_threshold
    ;;
esac
