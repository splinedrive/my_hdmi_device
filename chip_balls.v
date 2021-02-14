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
           input clk_25mhz,
`ifdef BLACKICE_MX
           output [3:0] hdmi_p,
           output [3:0] hdmi_n,
           output reg [7:0] led,
           output reg [3:0] led1 = 4'b1001
       );
`else
           output [3:0] gpdi_dp,
           output [7:0] led
       );
`endif

reg [7:0] vga_red;
reg [7:0] vga_blue;
reg [7:0] vga_green;

reg vga_hsync;
reg vga_vsync;
reg vga_blank;

localparam SYSTEM_CLK_MHZ = 25;
`ifdef BLACKICE_MX
localparam DDR_HDMI_TRANSFER = 1;
`else /* ulx3s */
localparam DDR_HDMI_TRANSFER = 1;
`endif

// calculate video timings
localparam x_res             = 640;
localparam y_res             = 480;
localparam frame_rate        = 60;

`include "video_timings.v"

// clock generator
`ifdef BLACKICE_MX
wire clk_x5;
wire tmds_clk = clk_x5;
wire pclk = clk_25mhz;

SB_PLL40_CORE #(
                  .FEEDBACK_PATH ("SIMPLE"),
                  .DIVR (4'b0000),
                  .DIVF (7'b0100111),
                  .DIVQ (3'b011),
                  .FILTER_RANGE (3'b010)
              ) uut (
                  .RESETB         (1'b1),
                  .BYPASS         (1'b0),
                  .REFERENCECLK   (clk_25mhz),
                  .PLLOUTGLOBAL   (clk_x5) // 5xpclk = 125MHz tmds clock
              );
`else /* ulx3s */
wire clk_locked;
wire [3:0] clocks;

ecp5pll
    #(
        .in_hz(SYSTEM_CLK_MHZ*1e6),
        .out0_hz(pixel_f * (DDR_HDMI_TRANSFER ? 5 : 10)),
        .out1_hz(pixel_f)
    )
    ecp5pll_inst
    (
        .clk_i(clk_25mhz),
        .clk_o(clocks),
        .locked(clk_locked)
    );

wire tmds_clk = clocks[0];
wire pclk = clocks[1];
`endif

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

`ifdef  BLACKICE_MX
wire clk = clk_25mhz;
reg [0:31] count = 0;
wire tick = (count == SYSTEM_CLK_MHZ * 1000_0);
always @(posedge clk) begin
    count <= (tick) ? 0 : count + 1;
end

reg [0:31] count1 = 0;
wire tick1 = (count1 == SYSTEM_CLK_MHZ * 1000_000);
always @(posedge clk) begin
    count1 <= (tick1) ? 0 : count1 + 1;
end

always @(posedge clk) begin
    if (tick) begin
        led <= vga_blue;
    end

    if (tick1) begin
        led1 <= led1 ^ 4'b1111;
    end
end
`else /* ulx3s */
reg [31:0] frame_cnt = 0;
wire new_frame = (vcnt == 0 && hcnt == 0) ;
wire fps = frame_cnt == 59;
reg toogle;
always @(posedge pclk) begin
    if (new_frame) frame_cnt <= (frame_cnt == 59) ? 0 : frame_cnt + 1;
    //toogle <= fps ? !toogle : toogle;
    toogle <= toogle ^ fps;
end

assign   led = {8{toogle}};
`endif

/* */
`ifdef BLACKICE_MX
localparam N = 20;
`else
localparam N = 35;
`endif
wire [N-1:0] draw_ball;
//reg [N-1:0] in_opposite = 0;
genvar i;
generate
    for (i = 0; i < N; i = i +1)
    begin: gen_ball
        ball #(
                 .START_X( i*10 % x_res),
                 .START_Y( i*10 % y_res),
                 .DELTA_X( 1+(i) % 4 ),
                 .DELTA_Y( 1+(i) % 4 ),
                 .BALL_WIDTH( 10 +i % 100 ),
                 .BALL_HEIGHT( 10 +i % 100  ),
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
wire [15:0] lfsr;
wire draw_stars = hcnt >= 0 && hcnt < 256 && vcnt >= 0 && vcnt < 256;
wire star_object = (&lfsr[15:6] & draw_stars);
LFSR #(16'b1_0000_0000_1011,0)
     lfsr_i(pclk, 1'b0, draw_stars, lfsr);

wire [15:0] lfsr1;
wire draw_stars1 = hcnt >= 256 && hcnt < 512 && vcnt >= 0 && vcnt < 256;
wire star_object1 = (&lfsr1[15:6] & draw_stars1);
LFSR #(16'b1000000001011,0)
     lfsr_i1(pclk, 1'b0, draw_stars1, lfsr1);

wire [15:0] lfsr2;
wire draw_stars2 = hcnt >= 512 && hcnt < (512+256) && vcnt >= 0 && vcnt < 256;
wire star_object2 = (&lfsr2[15:6] & draw_stars2);
LFSR #(16'b1000000001011,0)
     lfsr_i2(pclk, 1'b0, draw_stars2, lfsr2);

//////

wire [15:0] lfsr3;
wire draw_stars3 = hcnt >= 0 && hcnt < 256 && vcnt >= 224 && vcnt < 480;
wire star_object3 = (&lfsr3[15:6] & draw_stars3);
LFSR #(16'b1000000001011,0)
     lfsr_i3(pclk, 1'b0, draw_stars3, lfsr3);

wire [15:0] lfsr4;
wire draw_stars4 = hcnt >= 256 && hcnt < 512 && vcnt >= 224 && vcnt < 480;
wire star_object4 = (&lfsr4[15:6] & draw_stars4);
LFSR #(16'b1000000001011,0)
     lfsr_i4(pclk, 1'b0, draw_stars4, lfsr4);

wire [15:0] lfsr5;
wire draw_stars5 = hcnt >= 512 && hcnt < (512+256) && vcnt >= 224 && vcnt < 480;
wire star_object5 = (&lfsr5[15:6] & draw_stars5);
LFSR #(16'b1000000001011,0)
     lfsr_i5(pclk, 1'b0, draw_stars5, lfsr5);

wire stars = star_object  | star_object1 |
     star_object2 | star_object3 |
     star_object4 | star_object5;
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
    `ifdef BLACKICE_MX
        vga_red   <= vga_red_test>>1   | (stars | |draw_ball[6:0] | |draw_ball[9:0] | (&vcnt[4:0]|&hcnt[4:0]) ? 8'hff : 8'h0);
        vga_green <= vga_green_test>>1 | (stars | |draw_ball[15:7] ? 8'hff : 8'h0);
        vga_blue  <= vga_blue_test>>1  | (stars | |draw_ball[19:16] | (&vcnt[4:0]|&hcnt[4:0]) ? 8'hff : 8'h0);
    `else
        vga_red   <= vga_red_test>>1   | (stars | |draw_ball[10:0] | |draw_ball[20:11] | (&vcnt[4:0]|&hcnt[4:0]) ? 8'hff : 8'h0);
        vga_green <= vga_green_test>>1 | (stars | |draw_ball[20:11] ? 8'hff : 8'h0);
        vga_blue  <= vga_blue_test>>1  | (stars | |draw_ball[34:21] | (&vcnt[4:0]|&hcnt[4:0]) ? 8'hff : 8'h0);
    `endif
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
                tmds_clk,

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

`ifdef BLACKICE_MX
generate
    if (DDR_HDMI_TRANSFER) begin /* we have no other choice as DDR */
        SB_LVCMOS SB_LVCMOS_RED   (.DP(hdmi_p[2]), .DN(hdmi_n[2]), .clk_x5(tmds_clk), .tmds_signal(out_tmds_red));
        SB_LVCMOS SB_LVCMOS_GREEN (.DP(hdmi_p[1]), .DN(hdmi_n[1]), .clk_x5(tmds_clk), .tmds_signal(out_tmds_green));
        SB_LVCMOS SB_LVCMOS_BLUE  (.DP(hdmi_p[0]), .DN(hdmi_n[0]), .clk_x5(tmds_clk), .tmds_signal(out_tmds_blue));
        SB_LVCMOS SB_LVCMOS_CLK   (.DP(hdmi_p[3]), .DN(hdmi_n[3]), .clk_x5(tmds_clk), .tmds_signal(out_tmds_clk));
    end
endgenerate
`else
/* ulx3s can SDR and DDR */
generate
    if (DDR_HDMI_TRANSFER) begin
        ODDRX1F ddr0_clock (.D0(out_tmds_clk   [0] ), .D1(out_tmds_clk   [1] ), .Q(gpdi_dp[3]), .SCLK(tmds_clk), .RST(0));
        ODDRX1F ddr0_red   (.D0(out_tmds_red   [0] ), .D1(out_tmds_red   [1] ), .Q(gpdi_dp[2]), .SCLK(tmds_clk), .RST(0));
        ODDRX1F ddr0_green (.D0(out_tmds_green [0] ), .D1(out_tmds_green [1] ), .Q(gpdi_dp[1]), .SCLK(tmds_clk), .RST(0));
        ODDRX1F ddr0_blue  (.D0(out_tmds_blue  [0] ), .D1(out_tmds_blue  [1] ), .Q(gpdi_dp[0]), .SCLK(tmds_clk), .RST(0));
    end else begin
        assign gpdi_dp[3] = out_tmds_clk;
        assign gpdi_dp[2] = out_tmds_red;
        assign gpdi_dp[1] = out_tmds_green;
        assign gpdi_dp[0] = out_tmds_blue;
    end
endgenerate
`endif

endmodule

`ifdef BLACKICE_MX
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
`endif

