#!/bin/sh
# EC may take the fan back across suspend; restart the curve on resume.
[ "$1" = post ] && systemctl restart gpd-fan-curve.service
exit 0
