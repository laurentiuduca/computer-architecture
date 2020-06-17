// SPDX-License-Identifier: GPL-2.0
// Copyright (C) 2020, L-C. Duca

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module sep_baud_uart(sys_clk, reset,
				// Transceiver
				txd_o, 
				rxd_i,
				char_leds,
				//wen_i
				);

`include "inc_of_verifla.v"				

input			sys_clk;
input			reset;
output [7:0] char_leds;
//input wen_i;

// Transceiver
output txd_o;
reg [7:0] data_i;
wire tre_o;
wire wen_i;

// Receiver
input rxd_i;
wire [7:0] data_o;
wire rdy_o;

wire baud_clk_posedge;

/*reg [2:0] RESET_logic=3'b0;
always @(posedge sys_clk) RESET_logic={RESET_logic[1:0], 1'b1};
assign sys_rst_l=RESET_logic[2];
*/
wire sys_rst_l;
assign sys_rst_l = !reset;
uart_of_verifla 
		iUART (sys_clk,
				sys_rst_l,
				baud_clk_posedge,

				// Transmitter
				txd_o,
				wen_i,
				data_i,
				tre_o,

				// Receiver
				rxd_i,
				data_o,
				rdy_o		
			);


// we transmit what we receive.
single_pulse sp1 (sys_clk, sys_rst_l, baud_clk_posedge, rdy_o, wen_i);
// value of data to send is the received data.
assign char_leds = data_i;
always @(posedge sys_clk or negedge sys_rst_l)
begin
	if(~sys_rst_l)
		data_i = 8'h6E;
	else
		data_i = data_o+1;
end
			
endmodule
