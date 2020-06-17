// Author: L-C. Duca
// Date: 2015/11/20
// SPDX-License-Identifier: MIT

`timescale 1ns/1ps

module test_pipeline_biss;
    reg clk;
    reg rst;
    reg [15:0] a;
    wire [15:0] b,c,d;

    parameter PERIOD = 100;

	pipeline_biss_et1 ps_et1 (.clk(clk), .rst(rst), .a(a), .b(b));
	pipeline_biss_et2 ps_et2 (.clk(clk), .rst(rst), .b(b), .c(c));
	pipeline_biss_et3 ps_et3 (.clk(clk), .rst(rst), .c(c), .d(d));

    initial begin  // Open the results file...
        $dumpfile("simple.vcd");
        $dumpvars(0, test_pipeline_biss);
        #2000 // Final time
        $finish;
	end
	
	// Data stimulus
    initial begin
	clk = 1'b0;
	a = 0;
        rst = 1'b1;        #(2*PERIOD);
        rst = 1'b0;        #PERIOD;
		
        a = 1;        #PERIOD;
        a = 2;        #PERIOD;
        a = 3;        #PERIOD;
        a = 4;        #PERIOD;
        a = 5;        #PERIOD;
        a = 6;        #PERIOD;		
        a = 0;        #PERIOD;
    end

    // Clock process for clk
    always #(PERIOD*0.5) clk = ~clk;

endmodule

