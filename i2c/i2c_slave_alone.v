/*
 * Date: 20180924_1620
 * Author: Laurentiu-Cristian Duca, laurentiu.duca@gmail.com
 * This is a modified version of Alex Forencich i2c slave implementation (with MIT license)
 * with a i2c debouncer inspired from Steve Fielding i2c slave (with LGPL license).
 */

/*
Copyright (c) 2015-2017 Alex Forencich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

module i2c_slave(clk, rst, SCL, SDA, datain); 

// verifla
input rst;

//I2C
input clk;
input SCL;
inout SDA;
output [7:0] datain;

parameter slaveaddress = 7'b1110010;
//Count of bytes to be sent, send read value twice
parameter valuecnt = 3'b001;

// debounce sda and scl
`define DEB_I2C_LEN	10
reg sdaDeb=1'b1;
reg sclDeb=1'b1;
reg [`DEB_I2C_LEN-1:0] sdaPipe={`DEB_I2C_LEN{1'b1}};
reg [`DEB_I2C_LEN-1:0] sclPipe={`DEB_I2C_LEN{1'b1}};
always @(posedge clk) begin
    sdaPipe <= {sdaPipe[`DEB_I2C_LEN-2:0], SDA};
    sclPipe <= {sclPipe[`DEB_I2C_LEN-2:0], SCL};
    if (&sclPipe[`DEB_I2C_LEN-1:1] == 1'b1)
      sclDeb <= 1'b1;
    else if (|sclPipe[`DEB_I2C_LEN-1:1] == 1'b0)
      sclDeb <= 1'b0;
    if (&sdaPipe[`DEB_I2C_LEN-1:1] == 1'b1)
      sdaDeb <= 1'b1;
    else if (|sdaPipe[`DEB_I2C_LEN-1:1] == 1'b0)
      sdaDeb <= 1'b0;
end

reg [2:0] SCL_vec = 3'b111;  
always @(posedge clk) 
	SCL_vec <= {SCL_vec[1:0], sclDeb};
wire SCL_posedge = (SCL_vec[2:1] == 2'b01);  
wire SCL_negedge = (SCL_vec[2:1] == 2'b10);  

reg [2:0] SDA_vec = 3'b111;
always @(posedge clk) 
	SDA_vec <= {SDA_vec[1:0], sdaDeb};
//wire SDA_veced = SDA_vec[0] & SDA_vec[1] & SDA_vec[2];
wire SDA_posedge = (SDA_vec[2:1] == 2'b01);
wire SDA_negedge = (SDA_vec[2:1] == 2'b10);

//Detect start and stop
reg start = 1'b0;
always @(posedge clk)
	if(SDA_negedge)
		start = sclDeb;
reg stop = 1'b0;
always @(posedge clk)
	if(SDA_posedge)
		stop = sclDeb;

//Set cycle state 
reg incycle = 1'b0;
always @(posedge clk)
	if (start)
	begin
		if (incycle == 1'b0)
			incycle = 1'b1;
	end
	else if (stop)
	begin
		if (incycle == 1'b1)
			incycle = 1'b0;	
	end
	
//Address and incomming data handling
reg[7:0] bitcount = 0;
reg[6:0] address = 7'b0000000;
reg[7:0] datain = 8'b00000000;
reg rw = 1'b0;
reg addressmatch = 1'b0;
always @(posedge clk)
	if (~incycle)	
	begin
		//Reset the bit counter at the end of a sequence
		bitcount <= 0;
	end else if(SCL_posedge) begin
	   //Get the address
		if (bitcount < 7)
			address[6 - bitcount] <= SDA_vec[1];
		else if (bitcount == 7)
		begin
			rw <= SDA_vec[1];
			addressmatch <= (slaveaddress == address) ? 1'b1 : 1'b0;
		end else if ((bitcount >= 9) && (bitcount <= 16) && (~rw))
			//Receive data (currently only one byte)
			datain[16 - bitcount] <= SDA_vec[1];
		bitcount <= bitcount + 1;
	end
	
//ACK's and out going data
reg sdadata = 1'bz; 
reg [2:0] currvalue = 0;
always @(posedge clk)
	if(SCL_negedge) begin
		//ACK's
		if (((bitcount == 8) | ((bitcount == 17) & ~rw)) & (addressmatch)) begin
			sdadata <= 1'b0;
			currvalue <= 0;
		end
		//Data
		else if ((bitcount >= 9) & (rw) & (addressmatch) & (currvalue < valuecnt)) begin
			//Send Data  
			if (((bitcount - 9) - (currvalue * 9)) == 8)
			begin
				//Release SDA so master can ACK/NAK
				sdadata <= 1'bz;
				currvalue <= currvalue + 1;
			end else 
				//Modify this to send actual data, currently echoing incomming data valuecnt times.
				sdadata <= datain[7 - ((bitcount - 9) - (currvalue * 9))];
		end else 
			//Nothing (cause nothing tastes like fresca)
			sdadata <= 1'bz;
	end
assign SDA = sdadata;

endmodule
