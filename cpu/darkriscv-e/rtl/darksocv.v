/*
 * Copyright (c) 2018, Marcelo Samsoniuk
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 * * Redistributions of source code must retain the above copyright notice, this
 *   list of conditions and the following disclaimer.
 * 
 * * Redistributions in binary form must reproduce the above copyright notice,
 *   this list of conditions and the following disclaimer in the documentation
 *   and/or other materials provided with the distribution.
 * 
 * * Neither the name of the copyright holder nor the names of its
 *   contributors may be used to endorse or promote products derived from
 *   this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BYTE_EN LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
 */

// Updated by L-C. Duca

`timescale 1ns / 1ps
`include "../rtl/config.vh"

module darksocv
(
    input        XCLK,      // external clock
    input        XRES,      // external reset
    
    input        UART_RXD,  // UART receive line
    output       UART_TXD,  // UART transmit line

    output [3:0] LED,       // on-board leds
    output [3:0] DEBUG      // osciloscope
);

    // internal/external reset logic
	
    reg [7:0] IRES = -1;
`ifdef INVRES
    error
`else
    always@(posedge XCLK) IRES <= XRES==1 ? -1 : IRES[7] ? IRES-1 : 0; // reset high
`endif

    // clock generator logic
    
`ifdef BOARD_CK_REF
	error
`else    
    // when there is no need for a clock generator:
    wire CLK = XCLK;
    wire RES = IRES[7];    
`endif /* BOARD_CK_REF */
	
	
    // 0. ro/rw memories
	
`ifdef __HARVARD__

    reg [31:0] ROM [0:1023]; // ro memory
    reg [31:0] RAM [0:1023]; // rw memory

    // memory initialization

    integer i;
    initial
    begin
        for(i=0;i!=1024;i=i+1)
        begin        
            ROM[i] = 32'd0;
            RAM[i] = 32'd0;
        end

        // workaround for vivado: no path in simulation and .mem extension
        
`ifdef XILINX_SYNTHESIS
        $readmemh("darksocv.rom.mem",ROM);        
        $readmemh("darksocv.ram.mem",RAM);
`else
        $readmemh("../src/darksocv.rom.mem",ROM);        
        $readmemh("../src/darksocv.ram.mem",RAM);
`endif        
    end

`else /* __HARVARD__ */

    reg [31:0] MEM [0:2047]; // ro memory

    // memory initialization

    integer i;
    initial
    begin
        for(i=0;i!=2048;i=i+1)
        begin
            MEM[i] = 32'd0;
        end
        
        // workaround for vivado: no path in simulation and .mem extension
        
`ifdef XILINX_SIMULATOR
        $readmemh("darksocv.mem",MEM);
`else
        $readmemh("../src/darksocv.mem",MEM);
`endif 
    end

`endif /* __HARVARD__ */

    // darkriscv bus interface

    wire [31:0] INSTR_ADDR;
    wire [31:0] DATA_ADDR;
    wire [31:0] INSTR_DATA;    
    wire [31:0] CPU_DATA_OUT;        
    wire [31:0] DATA_FROM_MEM;
    wire        WR,RD;
    wire [3:0]  BYTE_EN;

    wire [31:0] IOMUX [0:3];

    reg  [15:0] GPIOFF = 0;
    reg  [15:0] LEDFF  = 0;
    
    wire HLT;
    
	
	// 1. ROM access
    reg [31:0] ROMFF;
    wire IHIT = 1;   

    always@(posedge CLK) // stage #0.5    
    begin
`ifdef __3STAGE__    
        if(!HLT)
`endif
        begin
`ifdef __HARVARD__
            ROMFF <= ROM[INSTR_ADDR[11:2]];
`else
            ROMFF <= MEM[INSTR_ADDR[12:2]];
`endif
        end
    end
    
    assign INSTR_DATA = ROMFF;


	// 2. RAM access
    // no cache!
    reg [31:0] RAMFF;
`ifdef __WAITSTATES__
    error
`elsif __3STAGE__
    // for single phase clock: 1 wait state in read op always required!
	// Load instruction takes 4 cycles: 
	// InstrDecode / RD=1, DATA_ADDR valid / RAMFF valid / write RAMFF to RegDest
    reg [1:0] DACK = 0;
    wire WHIT = 1;
    wire DHIT = !((RD||WR) && DACK!=1); // the WR operatio does not need ws. in this config.
    
    always@(posedge CLK) // stage #1.0
    begin
        DACK <= RES ? 0 : DACK ? DACK-1 : (RD||WR) ? 1 : 0; // wait-states
    end
`else /* __3STAGE__ */
	/* no wait states required */
	wire WHIT = 1;
    wire DHIT = 1;
`endif /* __3STAGE__ */
    
    always@(posedge CLK) // stage #1.5
    begin
`ifdef __HARVARD__
        RAMFF <= RAM[DATA_ADDR[11:2]];
`else
        RAMFF <= MEM[DATA_ADDR[12:2]];
`endif
    end

    reg [31:0] IOMUXFF;
    //individual byte/word/long selection, thanks to HYF!
    always@(posedge CLK)
    begin    
`ifdef __3STAGE__
        // read-modify-write operation w/ 1 wait-state:
        if(!HLT&&WR&&DATA_ADDR[31]==0/*&&DATA_ADDR[12]==1*/)
        begin
    `ifdef __HARVARD__
            RAM[DATA_ADDR[11:2]] <=
    `else
            MEM[DATA_ADDR[12:2]] <=
    `endif            
                                {
                                    BYTE_EN[3] ? CPU_DATA_OUT[3 * 8 + 7: 3 * 8] : RAMFF[3 * 8 + 7: 3 * 8],
                                    BYTE_EN[2] ? CPU_DATA_OUT[2 * 8 + 7: 2 * 8] : RAMFF[2 * 8 + 7: 2 * 8],
                                    BYTE_EN[1] ? CPU_DATA_OUT[1 * 8 + 7: 1 * 8] : RAMFF[1 * 8 + 7: 1 * 8],
                                    BYTE_EN[0] ? CPU_DATA_OUT[0 * 8 + 7: 0 * 8] : RAMFF[0 * 8 + 7: 0 * 8]
                                };
    	end /* if */

`else /* __3STAGE__ */
    // write-only operation w/ 0 wait-states:
    `ifdef __HARVARD__
        if(WR&&DATA_ADDR[31]==0&&BYTE_EN[3]) RAM[DATA_ADDR[11:2]][3 * 8 + 7: 3 * 8] <= CPU_DATA_OUT[3 * 8 + 7: 3 * 8];
        if(WR&&DATA_ADDR[31]==0&&BYTE_EN[2]) RAM[DATA_ADDR[11:2]][2 * 8 + 7: 2 * 8] <= CPU_DATA_OUT[2 * 8 + 7: 2 * 8];
        if(WR&&DATA_ADDR[31]==0&&BYTE_EN[1]) RAM[DATA_ADDR[11:2]][1 * 8 + 7: 1 * 8] <= CPU_DATA_OUT[1 * 8 + 7: 1 * 8];
        if(WR&&DATA_ADDR[31]==0&&BYTE_EN[0]) RAM[DATA_ADDR[11:2]][0 * 8 + 7: 0 * 8] <= CPU_DATA_OUT[0 * 8 + 7: 0 * 8];
    `else
        if(WR&&DATA_ADDR[31]==0&&BYTE_EN[3]) MEM[DATA_ADDR[12:2]][3 * 8 + 7: 3 * 8] <= CPU_DATA_OUT[3 * 8 + 7: 3 * 8];
        if(WR&&DATA_ADDR[31]==0&&BYTE_EN[2]) MEM[DATA_ADDR[12:2]][2 * 8 + 7: 2 * 8] <= CPU_DATA_OUT[2 * 8 + 7: 2 * 8];
        if(WR&&DATA_ADDR[31]==0&&BYTE_EN[1]) MEM[DATA_ADDR[12:2]][1 * 8 + 7: 1 * 8] <= CPU_DATA_OUT[1 * 8 + 7: 1 * 8];
        if(WR&&DATA_ADDR[31]==0&&BYTE_EN[0]) MEM[DATA_ADDR[12:2]][0 * 8 + 7: 0 * 8] <= CPU_DATA_OUT[0 * 8 + 7: 0 * 8];
    `endif

`endif /* __3STAGE__ */

        IOMUXFF <= IOMUX[DATA_ADDR[3:2]]; // read w/ 2 wait-states
    end /* always */

    assign DATA_FROM_MEM = DATA_ADDR[31] ? /*IOMUX[DATA_ADDR[3:2]]*/ IOMUXFF  : RAMFF;

	
    // 3. io for debug

    wire   [7:0] BOARD_ID = `BOARD_ID;              // board id
    wire   [7:0] BOARD_CM = (`BOARD_CK/1000000);    // board clock (MHz)
    wire   [7:0] BOARD_CK = (`BOARD_CK/10000)%100;  // board clock (kHz)

    assign IOMUX[0] = { BOARD_CK, BOARD_CM, BOARD_ID };
    //assign IOMUX[1] = from UART!
    assign IOMUX[2] = { GPIOFF, LEDFF };

    always@(posedge CLK)
    begin
		if(WR&&DATA_ADDR[31]&&DATA_ADDR[3:0]==4'b0100)
        begin
			// end simulation
			`ifdef SIMULATION
				$display("end simulation");
				$finish;
			`endif
		end
		if(WR&&DATA_ADDR[31]&&DATA_ADDR[3:0]==4'b1000)
        begin
            LEDFF <= CPU_DATA_OUT[15:0];
			`ifdef SIMULATION
				$display("LEDFF=%x", LEDFF);
			`endif
        end

        if(WR&&DATA_ADDR[31]&&DATA_ADDR[3:0]==4'b1010)
        begin
            GPIOFF <= CPU_DATA_OUT[31:16];
        end
    end

    assign HLT = !IHIT||!DHIT||!WHIT;

    // 4. darkuart
  
    wire [3:0] UDEBUG;

    darkuart
//    #( 
//      .BAUD((`BOARD_CK/115200))
//    )
    uart0
    (
      .CLK(CLK),
      .RES(RES),
      .RD(!HLT&&RD&&DATA_ADDR[31]&&DATA_ADDR[3:2]==1),
      .WR(!HLT&&WR&&DATA_ADDR[31]&&DATA_ADDR[3:2]==1),
      .BYTE_EN(BYTE_EN),
      .DATA_INPUT(CPU_DATA_OUT),
      .DATA_OUTPUT(IOMUX[1]),
      //.IRQ(BOARD_IRQ[1]),
      .RXD(UART_RXD),
      .TXD(UART_TXD),
      .DEBUG(UDEBUG)
    );

    // darkriscv

    wire [3:0] KDEBUG;

    darkriscv
//    #(
//        .RESET_PC(32'h00000000),
//        .RESET_SP(32'h00002000)
//    ) 
    core0 
    (
`ifdef __3STAGE__
        .CLK(CLK),
`else
		.CLK(!CLK),
`endif
        .RES(RES),
        .HLT(HLT),
`ifdef __THREADING__        
        .IREQ(|(IREQ^IACK)),
`endif        
        .INSTR_DATA(INSTR_DATA),
        .INSTR_ADDR(INSTR_ADDR),
        .DATA_INPUT(DATA_FROM_MEM),
        .DATA_OUTPUT(CPU_DATA_OUT),
        .DATA_ADDR(DATA_ADDR),        
        .BYTE_EN(BYTE_EN),
        .WR_EN(WR),
        .RD_EN(RD),
        .DEBUG(KDEBUG)
    );

`ifdef __ICARUS__
  integer j;
  initial
  begin
    $dumpfile("darksocv.vcd");
	$dumpvars(0, darksocv);
	  for (j = 0; j < 16; j = j + 1)
		  $dumpvars(1, darksocv.core0.RG[j]);
	  for (j = 1023; j > 1007; j = j - 1)
		  $dumpvars(0, darksocv.RAM[j]);
  end
`endif

    assign LED   = LEDFF[3:0];
    
    assign DEBUG = { 1'b0, GPIOFF[0], WR, RD }; // UDEBUG;

endmodule
