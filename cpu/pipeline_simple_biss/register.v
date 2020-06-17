// Author: L-C. Duca
// Date: 2015/11/20
// SPDX-License-Identifier: MIT


module register(clk, rst, next, out);
input clk, rst;
input [15:0] next;
output [15:0] out;
reg [15:0] out;

always @(posedge clk or posedge rst)
begin
	if(rst)
		out = 0;
	else
		out = next;
end

endmodule
