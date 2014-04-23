#!/bin/bash

XPROJECT=$1

cat > ${XPROJECT}.xst <<EOF
set -tmpdir "xst/projnav.tmp"
set -xsthdpdir "xst"
run
-ifn ${XPROJECT}.prj
-ifmt mixed
-ofn ${XPROJECT}
-ofmt NGC
-p xc3s500e-5-fg320
-top ${XPROJECT}
-opt_mode Speed
-opt_level 1
-iuc NO
-keep_hierarchy No
-netlist_hierarchy As_Optimized
-rtlview Yes
-glob_opt AllClockNets
-read_cores YES
-write_timing_constraints NO
-cross_clock_analysis NO
-hierarchy_separator /
-bus_delimiter <>
-case Maintain
-slice_utilization_ratio 100
-bram_utilization_ratio 100
-verilog2001 YES
-fsm_extract YES -fsm_encoding Auto
-safe_implementation No
-fsm_style LUT
-ram_extract Yes
-ram_style Auto
-rom_extract Yes
-mux_style Auto
-decoder_extract YES
-priority_extract Yes
-shreg_extract YES
-shift_extract YES
-xor_collapse YES
-rom_style Auto
-auto_bram_packing NO
-mux_extract Yes
-resource_sharing YES
-async_to_sync NO
-mult_style Auto
-iobuf YES
-max_fanout 100000
-bufg 24
-register_duplication YES
-register_balancing No
-slice_packing YES
-optimize_primitives NO
-use_clock_enable Yes
-use_sync_set Yes
-use_sync_reset Yes
-iob Auto
-equivalent_register_removal YES
-slice_utilization_ratio_maxmargin 5
EOF