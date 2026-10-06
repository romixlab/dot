#!/bin/sh
# systemd-sleep hook: the Broadcom PCIe Bluetooth (hci_bcm4377) on Apple
# Silicon stops answering after resume (hci0 "command 0x0c01 tx timeout"),
# so unload the driver before sleep and load it again on wake.
case "$1" in
  pre)
    modprobe -r hci_bcm4377
    ;;
  post)
    modprobe hci_bcm4377
    ;;
esac
