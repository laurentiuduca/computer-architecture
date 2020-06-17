// SPDX-License-Identifier: GPL-2.0
/*
Update: Laurentiu Duca, 20180808_1200:
	- consider baud_clk_posedge
*/
module uart_of_verifla	(	sys_clk,
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

input			sys_clk;
input			sys_rst_l;
output		baud_clk_posedge;

// Trasmitter
output			txd_o;
input			wen_i;
input	[7:0]	data_i;
output			tre_o;

// Receiver
input			rxd_i;
output	[7:0]	data_o;
output			rdy_o;

wire 			baud_clk_posedge;
wire	[7:0]	data_o;
wire			rdy_o;



// Instantiate the Transmitter
u_xmit_of_verifla txd1 (
		.clk_i(sys_clk), 
		.rst_i(!sys_rst_l), 
		.baud_clk_posedge(baud_clk_posedge),
		.data_i(data_i), 
		.wen_i(wen_i), 
		.txd_o(txd_o), 
		.tre_o(tre_o)
	);
/*
u_xmit  iXMIT(  .sys_clk(baud_clk),
				.sys_rst_l(sys_rst_l),

				.uart_wen_i(txd_o),
				.wen_i(wen_i),
				.data_i(data_i),
				.tre_o(tre_o)
			);
*/

// Instantiate the Receiver
u_rec_of_verifla rxd1(
		.clk_i(sys_clk),
		.rst_i(!sys_rst_l),//system signal
		.baud_clk_posedge(baud_clk_posedge),
		.rxd_i(rxd_i),//serial data in
		.rdy_o (rdy_o), .data_o(data_o) //data ready and parallel data out signal
		);
/*
u_rec iRECEIVER (// system connections
				.sys_rst_l(sys_rst_l),
				.sys_clk(baud_clk),
				// uart
				.uart_dataH(rxd_i),
				.data_o(data_o),
				.rdy_o(rdy_o)
				);
*/

// Instantiate the Baud Rate Generator

baud_of_verifla baud1(	.sys_clk(sys_clk),
			.sys_rst_l(sys_rst_l),		
			.baud_clk_posedge(baud_clk_posedge)
		);

/*
reg [2:0] baud_clk_vec=0;
always @(posedge sys_clk or negedge sys_rst_l)
begin
	if(~sys_rst_l)
		baud_clk_vec = 0;
	else
		baud_clk_vec = {baud_clk_vec[1:0], baud_clk};
end
wire baud_clk_posedge;
assign baud_clk_posedge=baud_clk_vec[2:1]==2'b01;
*/
endmodule
