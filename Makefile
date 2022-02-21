PROJ=chip_balls


RM         = rm -rf
VERILOG_FILES = ecp5pll.sv \
								tmds_encoder.v \
								my_vga_clk_generator.v \
								ball.v \
								hdmi_device.v \
								lfsr.v\

all: ${PROJ}.bit

%.json: %.v
	yosys -p "synth_ecp5 -json $@ -top ${PROJ}" ${VERILOG_FILES} $<

%_out.config: %.json
	nextpnr-ecp5 --json $< --textcfg $@ --85k --package CABGA381 --lpf ulx3s_v20.lpf

%.bit: %_out.config
	#ecppack --compress --freq 125 --input $< --bit $@
	ecppack --compress --input $< --bit $@

prog: ${PROJ}.bit
	fujprog $<

clean:
	$(RM) -f ${PROJ}.bit ${PROJ}_out.config ${PROJ}.json

.PHONY: prog clean
