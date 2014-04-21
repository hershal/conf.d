SRC=../src/rpn-calc.v ../src/seven-segment-controller.v ../src/seven-segment-rom.v ../src/divider.v ../src/button-input.v ../src/button-debouncer.v ../src/memory.v ../src/rpn-calc-controller.v
TESTBENCH=../src/rpn-calc-tb.v

PROJECT=rpn-calc
XPROJECT=rpn_calc
BOARD=Nexys2
CLKMODE=JtagClk

COMPILER=iverilog
COUTPUT=$(PROJECT).simv
SIMULATOR=vvp
VIEWER=gtkwave
WAVEFORMAT=lxt2
COFLAGS=-v -o
SFLAGS=-v
SOUTPUT=-$(WAVEFORMAT)
TBOUTPUT=waves.$(WAVEFORMAT)

PRJ_OUT=$(XPROJECT).prj
XST_CFG=$(XPROJECT).xst
UCFPINS=../src/$(PROJECT).ucf
NGDOUT=$(XPROJECT).ngd
MAPOUT=$(XPROJECT)_map.ncd $(XPROJECT).ngd $(XPROJECT).pcf
PARFILES=$(XPROJECT)_map.ncd $(XPROJECT).ncd $(XPROJECT).pcf
TRCEXML=$(XPROJECT).twx $(XPROJECT).ncd
TRCEOUT=$(XPROJECT).twr $(XPROJECT).pcf
UTOUT=$(XPROJECT).ut
BITOUT=$(XPROJECT).bit

$(COUTPUT): $(TESTBENCH) $(SRC)
	$(COMPILER) $(TESTBENCH) $(SRC) -o $(COUTPUT)
check : $(TESTBENCH) $(SRC)
	$(COMPILER) -v -E $(TESTBENCH) $(SRC)
sim: $(COUTPUT)
	$(SIMULATOR) $(SFLAGS) $(COUTPUT) $(SOUTPUT)
disp: $(TBOUTPUT)
	$(VIEWER) $(TBOUTPUT) &
$(TBOUTPUT): $(COUTPUT)
	$(SIMULATOR) $(SOPTIONS) $(COUTPUT) $(SOUTPUT)

xstgen: $(XST_CFG)
$(XST_CFG): 
	mkdir -p xst/projnav.tmp/
	./xst_gen.sh $(XPROJECT)

prjgen: $(PRJ_OUT) $(SRC)
$(PRJ_OUT): 
	rm -f $(PRJ_OUT)
	for i in $(SRC); do echo "verilog work \"$$i\"" >> $(PRJ_OUT); done

xst: $(XPROJECT).syr
$(XPROJECT).syr: $(XST_CFG) $(PRJ_OUT) $(SRC) $(UCFPINS)
	xst -intstyle ise -ifn $(XPROJECT).xst -ofn $(XPROJECT).syr

ngd: $(NGDOUT)
$(NGDOUT): $(XPROJECT).syr
	ngdbuild -intstyle ise -dd _ngo -nt timestamp -uc $(UCFPINS) -p xc3s500e-fg320-5 $(XPROJECT).ngc $(NGDOUT)

imp: $(TRCEOUT)
$(TRCEOUT): $(NGDOUT)
	map -intstyle ise -p xc3s500e-fg320-5 -cm area -ir off -pr off -c 100 -o $(MAPOUT)
	par -w -intstyle ise -ol high -t 1 $(PARFILES)
	trce -intstyle ise -v 3 -s 5 -n 3 -fastpaths -xml $(TRCEXML) -o $(TRCEOUT) -ucf $(UCFPINS)

utgen_jtag: $(UTOUT)
	CLKMODE=JtagClk
	./ut_gen.sh $(XPROJECT) $(CLKMODE)
utgen_cclk: $(UTOUT)
	CLKMODE=CClk
	./ut_gen.sh $(XPROJECT) $(CLKMODE)
$(UTOUT):
	./ut_gen.sh $(XPROJECT) $(CLKMODE)

bit: $(BITOUT)
$(BITOUT): $(TRCEOUT) $(UTOUT)
	bitgen -intstyle ise -f $(XPROJECT).ut $(XPROJECT).ncd

flash: $(BITOUT)
	djtgcfg prog -d $(BOARD) -i 0 -f $(BITOUT)
clean: 
	rm -f *.out *.lxt *.vcd *.lxt2 waves.* $(COUTPUT)
	rm -f *.xmsgs *.bgn *.bit *.bld *.cmd_log *.drc *.lso
	rm -f *.ncd *.ngc *.ngd *.ngr *.pad *.par *.pcf *.prj *.ptwx
	rm -f *.spl *.stx *.syr *.twr *.twx *.unroutes *.ut
	rm -f *.xpi *.xst *.html *.map *.mrp *.ncd *.ngm *.xrpt *.xrpt
	rm -f *.csv *.txt *.xrpt *.html *.xml *.xrpt 
	rm -f  webtalk*
	rm -rf *_ngo xlnx_auto* planAhead_run_*
