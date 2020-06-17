`timescale 1ns / 1ps
// Create Date:    16:23:47 09/25/2018 
// Author: Laurentiu-Cristian Duca
// SPDX-License-Identifier: GPL-2.0-or-later

module spi_slave_lcd(clk, SCK, SSEL, MOSI, MISO, output_valid, byte_data_received, byte_data_send);

input clk, SCK, SSEL, MOSI;
output MISO;
output [7:0] byte_data_received;
input [7:0] byte_data_send;
output output_valid;

reg MISO=0;
reg [2:0] i;
reg output_valid=0;
reg [7:0] //byte_data_send=8'h85, 
	byte_data_received=0;

reg [2:0] SCK_vec=3'b000;
always @(posedge clk)
	SCK_vec <= {SCK_vec[1:0], SCK};
wire SCK_rise=(SCK_vec[2:1]==2'b01);
//wire SCK_fall=(SCK_vec[2:1]==2'b10);

// SPI mode 0
always @(posedge clk) begin
	if (~SSEL) begin
		if(SCK_rise) begin
			byte_data_received[i] <= MOSI;
			if(i == 0) begin
				i <= 7;
				output_valid <= 1;
			end
			else begin
				output_valid <= 0;
				i <= i-1;
			end
		end
		if (SCK_vec[1] == 0) begin
			MISO <= byte_data_send[i];
		end
	end else begin
		i <= 7;
		output_valid <= 0;
	end
end

endmodule
