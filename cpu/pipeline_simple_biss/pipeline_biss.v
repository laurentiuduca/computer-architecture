// Author: L-C. Duca
// Date: 2015/11/20
// SPDX-License-Identifier: MIT


module pipeline_biss_et1 (clk, rst, a, b);
input clk, rst;
input [15:0] a;
output [15:0] b;
wire  [15:0] b;
reg [15:0] next_b;

register r1(.clk(clk), .rst(rst), .next(next_b), .out(b));

always @(*)
	if(a != 0)
		next_b = a + 10;
	else
		next_b = 0;
endmodule
//-----------------------------------------------


module pipeline_biss_et2 (clk, rst, b, c);
input clk, rst;
input [15:0] b;
output [15:0] c;
wire  [15:0] c;
reg [15:0] next_c;

register r2(.clk(clk), .rst(rst), .next(next_c), .out(c));

always @(*)
	if(b != 0)
		next_c = b + 100;
	else
		next_c = 0;		
endmodule
//-----------------------------------------------


module pipeline_biss_et3 (clk, rst, c, d);
input clk, rst;
input [15:0] c;
output [15:0] d;
wire  [15:0] d;
reg [15:0] next_d;

register r3(.clk(clk), .rst(rst), .next(next_d), .out(d));

always @(*)
	if(c != 0)
		next_d = c + 1000;
	else
		next_d = 0;		
endmodule
