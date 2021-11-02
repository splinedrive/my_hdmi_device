//
//Written by GowinSynthesis
//Product Version "GowinSynthesis V1.9.8"
//Tue Nov  2 23:09:08 2021

//Source file index table:
//file0 "\/home/hd/hacking/Gowin/IDE/ipcore/DDR/data/ddr.v"
`timescale 100 ps/100 ps
module Gowin_DDR (
  din,
  clk,
  q
)
;
input [0:0] din;
input clk;
output [1:0] q;
wire [0:0] ibuf_o;
wire VCC;
wire GND;
  IBUF \ibuf_gen[0].ibuf_inst  (
    .O(ibuf_o[0]),
    .I(din[0]) 
);
  IDDR \iddr_gen[0].iddr_inst  (
    .Q0(q[0]),
    .Q1(q[1]),
    .D(ibuf_o[0]),
    .CLK(clk) 
);
  VCC VCC_cZ (
    .V(VCC)
);
  GND GND_cZ (
    .G(GND)
);
  GSR GSR (
    .GSRI(VCC) 
);
endmodule /* Gowin_DDR */
