PIN_DEF = icestick.pcf
DEVICE = hx1k
PROJ=chip_balls
VERILOG_FILES = $(addprefix ../, \
							  tmds_encoder.v \
								my_vga_clk_generator.v \
								ball.v \
								hdmi_device.v \
								)

all: $(PROJ).rpt $(PROJ).bin

%.blif: %.v
	yosys -DBLACKICE_MX -DBLACKICE_MX -DBLACKICE_MX -DBLACKICE_MX -DBLACKICE_MX -DBLACKICE_MX -DBLACKICE_MX -DBLACKICE_MX -DBLACKICE_MX -p 'synth_ice40 -top $(PROJ) -json $(PROJ).json -blif $@' ${VERILOG_FILES} $<

%.asc: $(PIN_DEF) %.blif
	nextpnr-ice40 -r --freq 125 --timing-allow-fail --$(DEVICE) --package tq144  --json $(PROJ).json --asc $(PROJ).asc --opt-timing --pcf $(PIN_DEF)

%.bin: %.asc
	icepack $< $@

%.rpt: %.asc
	icetime -d $(DEVICE) -mtr $@ $<

prog: $(PROJ).bin
	iceprog $<

clean:
	rm -f $(PROJ).blif $(PROJ).asc $(PROJ).rpt $(PROJ).bin $(PROJ).json

.SECONDARY:
.PHONY: all prog clean
