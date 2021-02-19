/*
my_hdmi_device 

Copyright (C) 2021  Hirosh Dabui <hirosh@dabui.de>

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
*/
module chip_balls(
           input clk_12mhz,
           output [3:0] hdmi_p,
           output [3:0] hdmi_n,
           output reg [4:0] led,
           output test_pin
       );

reg [7:0] vga_red;
reg [7:0] vga_blue;
reg [7:0] vga_green;

reg vga_hsync;
reg vga_vsync;
reg vga_blank;

assign test_pin = pclk;
localparam DDR_HDMI_TRANSFER = 1;

// calculate video timings
localparam x_res             = 640;
localparam y_res             = 480;
localparam frame_rate        = 60;

`include "../video_timings.v"

// clock generator
wire clk_x5;
wire tmds_clk = clk_x5;

wire clk_125, locked;

pll pll_i(clk_12mhz /* 12 MHz h1x*/, clk_x5, locked);

clk_divn #(3, 5) clk_divn_25mhz(clk_x5, 1'b0, pclk);

wire [10:0] hcnt;
wire [10:0] vcnt;
wire hcycle;
wire vcycle;
wire hsync;
wire vsync;
wire blank;

my_vga_clk_generator
    #(
        .VPOL( 1 ),
        .HPOL( 1 ),
        .FRAME_RATE( frame_rate ),
        .VBP( vsync_back_porch ),
        .VFP( vsync_front_porch ),
        .VSLEN( vsync_pulse_width ),
        .VACTIVE( y_res ),
        .HBP( hsync_back_porch ),
        .HFP( hsync_front_porch ),
        .HSLEN( hsync_pulse_width ),
        .HACTIVE( x_res )
    )
    my_vga_clk_generator_i(
        .pclk(pclk),
        .out_hcnt(hcnt),
        .out_vcnt(vcnt),
        .out_hsync(hsync),
        .out_vsync(vsync),
        .out_blank(blank),
        .reset_n(1'b1)
    );

reg [5:0] frame_cnt = 0;
wire new_frame = (vcnt == 0 && hcnt == 0) ;
wire fps = frame_cnt == 59;
reg toogle;
always @(posedge pclk) begin
    if (new_frame) frame_cnt <= (frame_cnt == 59) ? 0 : frame_cnt + 1;
    toogle <= toogle ^ fps;
end

assign   led = {5{toogle}};
/* */
localparam N = 2;
wire [N-1:0] draw_ball;
//reg [N-1:0] in_opposite = 0;
genvar i;
generate
    for (i = 0; i < N; i = i +1)
    begin: gen_ball
        ball #(
                 .START_X( i*10 % x_res),
                 .START_Y( i*10 % y_res),
                 .DELTA_X( 1+(i*8)  ),
                 .DELTA_Y( 1+(i*8)  ),
                 .BALL_WIDTH( (i+1)*40 ),
                 .BALL_HEIGHT( (i+1)*40  ),
                 .X_RES( x_res ),
                 .Y_RES( y_res )
             ) ball_i (
                 .clk(pclk),
                 .i_vcnt(vcnt),
                 .i_hcnt(hcnt),
                 //.in_opposite(in_opposite[i]),
                 .i_opposite(1'b0),
                 .o_draw(draw_ball[i])
             );
    end
endgenerate
/////////////////////

wire [7:0] W              = {8{hcnt[7:0]==vcnt[7:0]}};
wire [7:0] A              = {8{hcnt[7:5]==3'h2 && vcnt[7:5]==3'h2}};
wire [7:0] vga_red_test   = ({hcnt[5:0] & {6{vcnt[4:3]==~hcnt[4:3]}}, 2'b00} | W) & ~A;
wire [7:0] vga_green_test = (hcnt[7:0] & {8{vcnt[6]}} | W) & ~A;
wire [7:0] vga_blue_test  = vcnt[7:0] | W | A;

always @(posedge pclk) begin
    vga_blank <= blank;
    vga_hsync <= hsync;
    vga_vsync <= vsync;

    if (~blank) begin
      vga_red   <= vga_red_test>>1   | (|draw_ball[0:0] ? 8'hff : 8'h0);
      vga_green <= vga_green_test>>1 ;//| (|draw_ball[1:1] ? 8'hff : 8'h0);
      vga_blue  <= vga_blue_test>>1  | (|draw_ball[1:1] ? 8'hff : 8'h0);

    end
    else begin
      vga_red <= 8'h0;
      vga_blue <= 8'h0;
      vga_green <= 8'h0;
    end
end

localparam OUT_TMDS_MSB = DDR_HDMI_TRANSFER ? 1 : 0;
wire [OUT_TMDS_MSB:0] out_tmds_red;
wire [OUT_TMDS_MSB:0] out_tmds_green;
wire [OUT_TMDS_MSB:0] out_tmds_blue;
wire [OUT_TMDS_MSB:0] out_tmds_clk;

hdmi_device #(.DDR_ENABLED(DDR_HDMI_TRANSFER)) hdmi_device_i(
                pclk,
                clk_x5,

                vga_red,
                vga_green,
                vga_blue,

                vga_blank,
                vga_vsync,
                vga_hsync,

                out_tmds_red,
                out_tmds_green,
                out_tmds_blue,
                out_tmds_clk
            );

generate
    if (DDR_HDMI_TRANSFER) begin /* we have no other choice as DDR */
        SB_LVCMOS SB_LVCMOS_RED   (.DP(hdmi_p[2]), .DN(hdmi_n[2]), .clk_x5(clk_x5), .tmds_signal(out_tmds_red));
        SB_LVCMOS SB_LVCMOS_GREEN (.DP(hdmi_p[1]), .DN(hdmi_n[1]), .clk_x5(clk_x5), .tmds_signal(out_tmds_green));
        SB_LVCMOS SB_LVCMOS_BLUE  (.DP(hdmi_p[0]), .DN(hdmi_n[0]), .clk_x5(clk_x5), .tmds_signal(out_tmds_blue));
        SB_LVCMOS SB_LVCMOS_CLK   (.DP(hdmi_p[3]), .DN(hdmi_n[3]), .clk_x5(clk_x5), .tmds_signal(out_tmds_clk));
    end
endgenerate
endmodule
/**
 * PLL configuration
 *
 * This Verilog module was generated automatically
 * using the icepll tool from the IceStorm project.
 * Use at your own risk.
 *
 * Given input frequency:        12.000 MHz
 * Requested output frequency:  125.000 MHz
 * Achieved output frequency:   124.500 MHz
 */

module pll(
        input  clock_in,
        output clock_out,
        output locked
        );

SB_PLL40_CORE #(
                .FEEDBACK_PATH("SIMPLE"),
                .DIVR(4'b0000),         // DIVR =  0
                .DIVF(7'b1010010),      // DIVF = 82
                .DIVQ(3'b011),          // DIVQ =  3
                .FILTER_RANGE(3'b001)   // FILTER_RANGE = 1
        ) uut (
                .LOCK(locked),
                .RESETB(1'b1),
                .BYPASS(1'b0),
                .REFERENCECLK(clock_in),
                .PLLOUTCORE(clock_out)
                );

endmodule

module clk_divn #(
  parameter WIDTH = 3,
  parameter N = 5)

  (clk,reset, clk_out);

  input clk;
  input reset;
  output clk_out;

  reg [WIDTH-1:0] pos_count, neg_count;
  wire [WIDTH-1:0] r_nxt;

  always @(posedge clk)
    if (reset)
      pos_count <=0;
    else if (pos_count ==N-1) pos_count <= 0;
    else pos_count<= pos_count +1;

    always @(negedge clk)
      if (reset)
        neg_count <=0;
      else  if (neg_count ==N-1) neg_count <= 0;
      else neg_count<= neg_count +1;

      assign clk_out = ((pos_count > (N>>1)) | (neg_count > (N>>1)));
endmodule

// LVDS Double Data RAGE (DDR) Output
module SB_LVCMOS(input DP, input DN, input clk_x5, input [1:0] tmds_signal);
defparam tmds_p.PIN_TYPE = 6'b010000;
defparam tmds_p.IO_STANDARD = "SB_LVCMOS";
SB_IO tmds_p (
          .PACKAGE_PIN (DP),
          .CLOCK_ENABLE (1'b1),
          .OUTPUT_CLK (clk_x5),
          .OUTPUT_ENABLE (1'b1),
          .D_OUT_0 (tmds_signal[1]),
          .D_OUT_1 (tmds_signal[0])
      );

defparam tmds_n.PIN_TYPE = 6'b010000;
defparam tmds_n.IO_STANDARD = "SB_LVCMOS";
SB_IO tmds_n (
          .PACKAGE_PIN (DN),
          .CLOCK_ENABLE (1'b1),
          .OUTPUT_CLK (clk_x5),
          .OUTPUT_ENABLE (1'b1),
          .D_OUT_0 (~tmds_signal[1]),
          .D_OUT_1 (~tmds_signal[0])
      );
// D_OUT_0 and D_OUT_1 swapped?
// https://github.com/YosysHQ/yosys/issues/330
endmodule

