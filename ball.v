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
/* verilator lint_off WIDTH */
module ball(
           input clk,
           input [10:0] i_vcnt,
           input [10:0] i_hcnt,
           input i_opposite,
           output reg o_draw
       );

parameter START_X = 0;
parameter START_Y = 0;
parameter DELTA_X = 1;
parameter DELTA_Y = 1;
parameter BALL_WIDTH = 30;
parameter BALL_HEIGHT = 30;
parameter X_RES = 640;
parameter Y_RES = 480;

wire [10:0] ball_xdiff = i_hcnt - ball_x;
wire [10:0] ball_ydiff = i_vcnt - ball_y;


always @(posedge clk) begin
    o_draw <= (ball_xdiff < BALL_WIDTH) && (ball_ydiff < BALL_HEIGHT);
end

wire ball_collision_x = (ball_x >= (X_RES - BALL_WIDTH));
wire ball_collision_y = (ball_y >= (Y_RES - BALL_HEIGHT));

reg [10:0] ball_x = START_X;
reg [10:0] ball_y = START_Y;

reg [10:0] delta_x = DELTA_X;
reg [10:0] delta_y = DELTA_Y;

reg ball_collision_x_s = 0;
always @(posedge clk) begin
    ball_collision_x_s <= ball_collision_x;
    if ((~ball_collision_x_s & ball_collision_x) | i_opposite) begin
        delta_x <= -delta_x;
    end
end

reg ball_collision_y_s = 0;
always @(posedge clk) begin
    ball_collision_y_s <= ball_collision_y;
    if ((~ball_collision_y_s & ball_collision_y) | i_opposite) begin
        delta_y <= -delta_y;
    end
end

always @(posedge clk) begin
    if (!i_vcnt && !i_hcnt) begin
        ball_x <= ball_x + delta_x;
        ball_y <= ball_y + delta_y;
    end
end
endmodule
