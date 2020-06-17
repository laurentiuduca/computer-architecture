// SPDX-License-Identifier: GPL-2.0
// Copyright (C) 2020, L-C. Duca

`timescale 1ns / 1ps

module test;
reg clk, rst_l;
reg ub;
wire ubsing;

single_pulse sp1(.clk(clk), .rst_l(rst_l), .ub(ub), .ubsing(ubsing));

always #5 clk = ~clk;

initial begin
	ub = 0;
	clk = 0;
	rst_l = 0;
	#25;
	rst_l = 1;
	#30;
	ub = 1;
	#50;
	ub = 0;
end

`ifdef __ICARUS__
  initial
  begin
	$dumpfile("single_pulse.vcd");
    $dumpvars(0, test);
	#200;
	$finish;
  end
`endif

endmodule

