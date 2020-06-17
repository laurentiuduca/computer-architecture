// SPDX-License-Identifier: GPL-2.0
// Copyright (C) 2020, L-C. Duca

`timescale 1ns/1ps
`include "wb_def.v"
  
module wb_slave	(input clk_i, rst_i, slave_we_i, slave_stb_i, slave_cyc_i,
				 input[`dw-1:0] slave_dat_i, output reg slave_ack_o, output reg [`dw-1:0] slave_dat_o);

   parameter slave_param = `dw'd0;
   
   always @(posedge clk_i or posedge rst_i)
	begin
		if(rst_i) begin
			slave_ack_o = 0;
			slave_dat_o = 0;
		end else begin
			slave_ack_o = slave_stb_i && slave_cyc_i;
			if (slave_cyc_i && slave_stb_i && slave_we_i)
			begin
				slave_dat_o = slave_param;
				$display("slave_slave_1: time=%dns slave_dat_i=%h\n", $time, slave_dat_i);
			end
		end
   end

      
endmodule
