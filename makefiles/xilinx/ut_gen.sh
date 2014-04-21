#!/bin/bash

XPROJECT=$1
CLKMODE=$2

cat > ${XPROJECT}.ut <<EOF
-w
-g DebugBitstream:No
-g Binary:no
-g CRC:Enable
-g ConfigRate:1
-g ProgPin:PullUp
-g DonePin:PullUp
-g TckPin:PullUp
-g TdiPin:PullUp
-g TdoPin:PullUp
-g TmsPin:PullUp
-g UnusedPin:PullDown
-g UserID:0xFFFFFFFF
-g DCMShutdown:Disable
-g StartUpClk:${CLKMODE}
-g DONE_cycle:4
-g GTS_cycle:5
-g GWE_cycle:6
-g LCK_cycle:NoWait
-g Security:None
-g DonePipe:Yes
-g DriveDone:No
EOF
