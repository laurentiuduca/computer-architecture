`timescale 1ns / 1ps

/* Copyright (C) 2020 L-C. Duca
 * SPDX-License-Identifier: GPL-2.0
 * date: 2020/03/23
 */


module testmul;

	// Inputs
	reg clk;
	reg rst;
	reg [3:0] m;
	reg [3:0] r;
	reg start;

	// Outputs
	wire [7:0] prod;
	wire done;

	// Instantiate the Unit Under Test (UUT)
	mul #(4) uut (
		.clk(clk), 
		.rst(rst), 
		.m(m), 
		.r(r), 
		.prod(prod), 
		.start(start), 
		.done(done)
	);

	always #5 clk = ~clk;

	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 1;
		m = 5;
		r = 6;
		start = 0;
		// Wait 100 ns for global reset to finish
		#25;
      rst = 0;
		#10;
		// Add stimulus here
		start = 1;
		#20;
		start = 0;
	end
      
endmodule

