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

`ifndef LFSR_V
`define LFSR_V

/*
Configurable Linear Feedback Shift Register.
*/

module LFSR(clk, reset, enable, lfsr);

parameter TAPS   = 8'b11101;	// bitmask for taps
parameter INVERT = 0;		// invert feedback bit?
localparam NBITS  = $size(TAPS); // bit width (derived from TAPS)

input clk, reset;
input enable;			// only perform shift when enable=1
output reg [NBITS-1:0] lfsr = ~0;  // shift register

wire feedback = lfsr[NBITS-1] ^ INVERT;

always @(posedge clk)
begin
    if (reset)
        lfsr <= {lfsr[NBITS-2:0], 1'b1}; // reset loads with all 1s
    else if (enable)
        lfsr <= {lfsr[NBITS-2:0], 1'b0} ^ (feedback ? TAPS : 0);
end

endmodule

`endif

