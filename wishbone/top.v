// SPDX-License-Identifier: GPL-2.0
// Copyright (C) 2020, L-C. Duca

`timescale 1ns/1ps
`include "wb_def.v"

module top;

reg clk_i, rst_i;
	
always #50 clk_i = ~clk_i;
	
initial begin
	$dumpfile("wb.vcd");
	$dumpvars(0, top);
	clk_i = 0;
	rst_i = 1;
	#250;
	rst_i = 0;
	#2000;
	$finish;
end
   
   // master 0 <-> WISHBONE
   wire [`dw-1:0] 	m0_dat_i;	// input data bus
   wire			m0_cyc, m0_stb, m0_we;
   wire [`aw-1:0] 	m0_adr;	// address bus outputs
   wire [`selw-1:0] 		m0_sel;	// byte select outputs
   wire [`dw-1:0] 	m0_dat_o;	// output data bus
   wire			m0_ack, m0_err, m0_rty, m0_cab;
   wire [2:0] 		m0_cti;	// cycle type identifier
   wire [1:0] 		m0_bte;	// burst type extension

   // master1 <-> WISHBONE
   wire [`dw-1:0] 	m1_dat_i;	// input data bus
   wire			m1_cyc, m1_stb, m1_we;
   wire [`aw-1:0] 	m1_adr;	// address bus outputs
   wire [`selw-1:0] 		m1_sel;	// byte select outputs
   wire [`dw-1:0] 	m1_dat_o;	// output data bus
   wire			m1_ack, m1_err, m1_rty, m1_cab;
   wire [2:0] 		m1_cti;	// cycle type identifier
   wire [1:0] 		m1_bte;	// burst type extension

   // WISHBONE <=> I/O slave 0
   wire [`aw-1:0] 	s0_addr;	// address bus
   wire [`dw-1:0] 	s0_dat_i;	// input data bus
   wire [`dw-1:0] 	s0_dat_o;	// output data bus
   wire 		s0_ack, s0_cyc, s0_stb, s0_we;
   wire [3:0] 		s0_sel;
   
   // WISHBONE <=> I/O slave 1
   wire [`aw-1:0] 	s1_addr;
   wire [`dw-1:0] 	s1_dat_i;
   wire [`dw-1:0] 	s1_dat_o;
   wire 		s1_we, s1_cyc, s1_stb, s1_ack;

	// Instantiate masters
	wb_master #(`dw'h20, `aw'h40) master0 (
      .clk_i(clk_i), .rst_i(rst_i),
	  .m_cyc_o(m0_cyc), .m_stb_o(m0_stb), .m_we_o(m0_we), 
	  .m_addr_o(m0_adr), .m_ack_i(m0_ack), 
      .m_sel_o(m0_sel), .m_data_o(m0_dat_o), .m_data_i(m0_dat_i)
     );
	wb_master #(`dw'h30, `aw'h90) master1 (
      .clk_i(clk_i), .rst_i(rst_i),
	  .m_cyc_o(m1_cyc), .m_stb_o(m1_stb), .m_we_o(m1_we), 
	  .m_addr_o(m1_adr), .m_ack_i(m1_ack), 
	  .m_sel_o(m1_sel), .m_data_o(m1_dat_o), .m_data_i(m1_dat_i)
     );
     
    // Instantiate slaves
	wb_slave #(`dw'h25) slave0 (
	  .clk_i(clk_i), .rst_i(rst_i), 
	  .slave_we_i(s0_we), .slave_stb_i(s0_stb), .slave_cyc_i(s0_cyc), 
      .slave_dat_i(s0_dat_o), .slave_dat_o(s0_dat_i), 
      .slave_ack_o(s0_ack));
	wb_slave #(`dw'h35) slave1 (
	  .clk_i(clk_i), .rst_i(rst_i), 
      .slave_we_i(s1_we), .slave_stb_i(s1_stb), .slave_cyc_i(s1_cyc), 
      .slave_dat_i(s1_dat_o), .slave_dat_o(s1_dat_i), 
      .slave_ack_o(s1_ack));
   
    // Instantiate wishbone bus
	wb_top #(8, 8'h40, 8, 8'h90) wb_bus ( 
	   .clk_i(clk_i), .rst_i(rst_i),
	   // Master 0 Interface
	   .m0_dat_i(m0_dat_o), .m0_dat_o(m0_dat_i),
	   .m0_adr_i(m0_adr), .m0_sel_i(m0_sel),
	   .m0_we_i(m0_we), .m0_cyc_i(m0_cyc), .m0_stb_i(m0_stb),
	   .m0_cab_i(m0_cab), .m0_ack_o(m0_ack), .m0_err_o(m0_err), .m0_rty_o(m0_rty), .m0_cti_i(m0_cti), .m0_bte_i(m0_bte),
	   // Master 1 Interface
	   .m1_dat_i(m1_dat_o), .m1_dat_o(m1_dat_i),
	   .m1_adr_i(m1_adr), .m1_sel_i(m1_sel),
	   .m1_we_i(m1_we), .m1_cyc_i(m1_cyc), .m1_stb_i(m1_stb),
	   .m1_cab_i(m1_cab), .m1_ack_o(m1_ack), .m1_err_o(m1_err), .m1_rty_o(m1_rty), .m1_cti_i(m1_cti), .m1_bte_i(m1_bte),
	   // Slave 0 Interface
	   .s0_dat_o(s0_dat_o), .s0_dat_i(s0_dat_i), 				
	   .s0_adr_o(s0_addr), .s0_sel_o(s0_sel),
	   .s0_we_o(s0_we), .s0_cyc_o(s0_cyc), .s0_stb_o(s0_stb),
	   .s0_cab_o(), .s0_ack_i(s0_ack), .s0_err_i(1'b0), .s0_rty_i(1'b0), .s0_cti_o(), .s0_bte_o(),
	   // Slave 1 Interface
	   .s1_dat_o(s1_dat_o), .s1_dat_i(s1_dat_i), 				
	   .s1_adr_o(s1_addr), .s1_sel_o(),
	   .s1_we_o(s1_we), .s1_cyc_o(s1_cyc), .s1_stb_o(s1_stb),
	   .s1_cab_o(), .s1_ack_i(s1_ack), .s1_err_i(1'b0), .s1_rty_i(1'b0), .s1_cti_o(), .s1_bte_o(),
	   .grant_o());

endmodule
