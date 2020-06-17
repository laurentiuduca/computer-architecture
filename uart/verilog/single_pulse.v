`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:17:26 02/23/2007 
// Design Name: 
// Module Name:    single_pulse 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
// Author: L-C. Duca
// SPDX-License-Identifier: GPL-2.0
//
//////////////////////////////////////////////////////////////////////////////////
module single_pulse(clk, reset, baud_clk_posedge, ub, ubsing);
input clk, reset, baud_clk_posedge;
input ub;
output ubsing;
reg [1:0] q;


/*
Truth table
====
before (posedge clk) | after (posedge clk)
ub / state(q1q0) | state(q1q0) / ubsing
0 / 00 | 00 / 0
1 / 00 | 01 / 1
x / 01 | 10 / 0
0 / 10 | 00 / 0
1 / 10 | 10 / 0

Notes:
- works only if the (posedge ub) comes 2 clk periods after the prevoius (negedge ub).
- after reset, ub can be either 0 or 1.
*/

assign ubsing = q[0];

always @ (posedge clk or negedge reset)
begin

if(~reset)
begin
	q[0] <= 0;
	q[1] <= 0;
end
else if (baud_clk_posedge)
	begin
		q[0] <= ~q[0] && ub && ~q[1];
		q[1] <= q[0] || (~q[0] && ub && q[1]);
	end
end


endmodule
