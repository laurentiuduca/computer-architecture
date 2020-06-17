`timescale 1ns / 1ps

/* Copyright (C) 2020 L-C. Duca
 * SPDX-License-Identifier: GPL-2.0
 * date: 2020/03/23
 */


module mul(clk, rst, m, r, prod, start, done);

parameter N_BITS=4;

input clk, rst, start;
input [N_BITS-1:0] m, r;
output done;
output [2*N_BITS-1:0] prod;
reg [2*N_BITS-1:0] prod, a, next_prod, next_a;
reg state, next_state;
reg [N_BITS-1:0] raux, next_raux;
wire done;

assign done = (state == 1);

always @(posedge clk or posedge rst) 
begin
	if(rst) begin
		prod <= 0;
		state <= 1;
		a <= 0;
		raux <= 0;
	end else begin
		state <= next_state;
		prod <= next_prod;
		a <= next_a;
		raux <= next_raux;
	end
end

always @(*) 
begin
	next_a <= a;
	next_prod <= prod;
	next_state <= state;
	next_raux <= raux;
	case(state)
	0:	if(raux != 0) begin
			next_raux <= raux >> 1;
			if(raux[0])
				next_prod <= prod + a;
			next_a <= a << 1;
		end else
			next_state <= 1;
	1: if(start) begin
			next_state <= 0;
			next_a <= {{N_BITS{1'b0}}, m};
			next_prod <= 0;
			next_raux <= r;
		end
	endcase
end

endmodule
