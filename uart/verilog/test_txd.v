// SPDX-License-Identifier: GPL-2.0
// Copyright (C) 2020, L-C. Duca.

`timescale 1ns/1ps

module test_txd;

	reg clk_i, rst_i;
	wire sys_rst_l;
	wire baud_clk_posedge;
	reg wen_i;
	wire txd_o, tre_o, rdy_o;
	wire [7:0] data_o;
	reg [7:0] data_i;

	assign sys_rst_l = ~rst_i;

	u_xmit_of_verifla uart_txd1(.clk_i(clk_i), .rst_i(rst_i), .baud_clk_posedge(baud_clk_posedge),
			.data_i(data_i), .wen_i(wen_i), .txd_o(txd_o), .tre_o(tre_o));

	u_rec_of_verifla uart_rxd1(.clk_i(clk_i), .rst_i(rst_i), .baud_clk_posedge(baud_clk_posedge),
			.rxd_i(txd_o), .rdy_o(rdy_o), .data_o(data_o));
			
	baud_of_verifla baud1(.sys_clk(clk_i), .sys_rst_l(sys_rst_l), .baud_clk_posedge(baud_clk_posedge));
	
	always #5 clk_i = ~clk_i;
	
   initial
   begin
		clk_i = 0;
		rst_i = 1;
		data_i <= 0;
		wen_i = 0;
		#2000;
			
		rst_i = 0;
		#4000;

		data_i <= 8'h61;
		wen_i <= 1;
		#2000;
		wen_i <= 0;
		#2000;
		
		#200000;
		$finish;
   end
	
endmodule

