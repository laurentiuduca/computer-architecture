// Update: 20180814_1555, author: Laurentiu Duca
// User readable form.
// Create Date:    16:17:26 02/23/2007 
// Additional Comments: single pulse from a multi-periods-contiguos pulse
// Author: Laurentiu Duca
// SPDX-License-Identifier: GPL-2.0

`timescale 1ns / 1ps

module single_pulse(clk, rst_l, ub, ubsing);
input clk, rst_l;
input ub;
output ubsing;


reg [1:0] next_state, state;
reg ubsing_reg, next_ubsing_reg;

assign ubsing = ubsing_reg;
  
always @(posedge clk or negedge rst_l)
begin
	if (~rst_l) begin
			state <= 0;
			ubsing_reg <= 0;
	end else begin
			state <= next_state;
			ubsing_reg <= next_ubsing_reg;
	end
end

always @(*)
begin
		next_state <= state;
		next_ubsing_reg <= 0;
		case (state)
		0: if (ub == 1)
				next_state <= 1;
		1: begin
			next_ubsing_reg <= 1;
		     if (ub == 0)
				next_state <= 0;
			else
				next_state <= 2;
		end
		2: if (ub == 0)
				next_state <= 0;
		endcase
end


endmodule
