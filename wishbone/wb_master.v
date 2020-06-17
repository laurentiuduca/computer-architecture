// SPDX-License-Identifier: GPL-2.0
// Copyright (C) 2020, L-C. Duca

`timescale 1ns/1ps
`include "wb_def.v"

module wb_master (input clk_i, input rst_i,
					output reg m_cyc_o, output reg m_stb_o, output reg m_we_o,
				  output reg [`aw-1:0] m_addr_o,
					input m_ack_i,
					output reg [`selw-1:0] m_sel_o,
				  output reg [`dw-1:0] m_data_o,
				  input [`dw-1:0] m_data_i);
	
   	parameter master_param = `dw'd0;
		parameter slave_address = `aw'd0;
	reg transfer_done;
	
	always @(posedge clk_i or posedge rst_i)
	begin
		if(rst_i) begin
			transfer_done = 0;
			m_cyc_o = 0; m_stb_o = 0; m_we_o = 0;
			m_sel_o = {`selw{1'b1}};
			m_data_o = 0;
			m_addr_o = 0;
		end else if(!transfer_done) begin
			if(m_ack_i) begin
				transfer_done = 1;
				$display("wb_master: time=%dns m_data_i=%h\n", $time, m_data_i);
				m_cyc_o = 0; m_stb_o = 0; m_we_o = 0;
			end
			else begin
				m_cyc_o = 1; m_stb_o = 1; m_we_o = 1;
				// select all bytes
				m_sel_o = {`selw{1'b1}};
				m_data_o = master_param;
				m_addr_o = slave_address;
			end	
		end
   end

endmodule
