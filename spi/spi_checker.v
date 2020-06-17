`timescale 1ns / 1ps
// Create Date:    11:58:12 10/13/2018 
// Author: Laurentiu-Cristian Duca (laurentiu.duca@gmail.com)
// SPDX-License-Identifier: GPL-2.0-or-later

module spi_checker(clk, rst, 
	SCK, SSEL, MOSI, MISO, SSEL2, leds, btn);//,
//	uart_REC_dataH, uart_XMIT_dataH);

//input uart_REC_dataH;
//output uart_XMIT_dataH;
	
input clk, rst;
input btn;
input SCK, SSEL, MOSI, SSEL2;
output MISO;
output [7:0] leds;

wire spi_output_valid; //, spi_output_valid_sing;
wire [7:0] byte_data_received;
wire [7:0] byte_data_send;

// VeriFLA
//top_of_verifla verifla (.clk(clk), .rst_l(!rst), .sys_run(1'b1),
				//.data_in({cnt[1:0], spi_output_valid_sing, spi_to_send[7], SCK, SSEL, MOSI, MISO}),
				// Transceiver
				//.uart_XMIT_dataH(uart_XMIT_dataH), .uart_REC_dataH(uart_REC_dataH));

// Debouncer
`define DEB_LEN 10
// SCK
reg sck_deb=1'b0;
reg [`DEB_LEN-1:0] sck_pipe={`DEB_LEN{1'b0}};
always @(posedge clk) begin
    sck_pipe <= {sck_pipe[`DEB_LEN-2:0], SCK};
    if (&sck_pipe[`DEB_LEN-1:1] == 1'b1)
      sck_deb <= 1'b1;
    else if (|sck_pipe[`DEB_LEN-1:1] == 1'b0)
      sck_deb <= 1'b0;
end
// SSEL
reg ssel_deb=1'b1;
reg [`DEB_LEN-1:0] ssel_pipe={`DEB_LEN{1'b1}};
always @(posedge clk) begin
    ssel_pipe <= {ssel_pipe[`DEB_LEN-2:0], SSEL2};
    if (&ssel_pipe[`DEB_LEN-1:1] == 1'b1)
      ssel_deb <= 1'b1;
    else if (|ssel_pipe[`DEB_LEN-1:1] == 1'b0)
      ssel_deb <= 1'b0;
end

spi_slave_lcd si (.clk(clk), .SCK(sck_deb), .SSEL(ssel_deb), .MOSI(MOSI), .MISO(MISO), 
	.output_valid(spi_output_valid), .byte_data_received(byte_data_received), .byte_data_send(byte_data_send));
//single_pulse sp1 (.clk(clk), .rst_l(!rst), .ub(spi_output_valid), .ubsing(spi_output_valid_sing));

reg [2:0] SCK_vec=3'b000;
always @(posedge clk)
	SCK_vec <= {SCK_vec[1:0], sck_deb};
wire SCK_rise=(SCK_vec[2:1]==2'b01);
reg [5:0] sck_rise_cnt;

always @(posedge clk or posedge rst)
begin
	if(rst)
		sck_rise_cnt = 0;
	else
		if(SCK_rise)
			sck_rise_cnt = sck_rise_cnt + 1;
end

assign byte_data_send = 8'h61 + {2'b00, sck_rise_cnt >> 3};

assign leds= (btn==1'b1) ? {byte_data_received} 
	: {spi_output_valid, SSEL, ssel_deb, sck_rise_cnt[4:0]};

endmodule
