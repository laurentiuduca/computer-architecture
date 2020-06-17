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

// implemented opcodes:

`define OPCODE_LUI     7'b01101_11      // lui   rd,imm[31:12]
`define OPCODE_AUIPC   7'b00101_11      // auipc rd,imm[31:12]
`define OPCODE_JAL     7'b11011_11      // jal   rd,imm[xxxxx]
`define OPCODE_JALR    7'b11001_11      // jalr  rd,rs1,imm[11:0] 
`define OPCODE_BCC     7'b11000_11      // bcc   rs1,rs2,imm[12:1]
`define OPCODE_LCC     7'b00000_11      // lxx   rd,rs1,imm[11:0]
`define OPCODE_SCC     7'b01000_11      // sxx   rs1,rs2,imm[11:0]
`define OPCODE_MCC     7'b00100_11      // xxxi  rd,rs1,imm[11:0]
`define OPCODE_RCC     7'b01100_11      // xxx   rd,rs1,rs2 
`define OPCODE_MAC     7'b11111_11      // mac   rd,rs1,rs2

// not implemented opcodes:

`define OPCODE_FCC     7'b00011_11      // fencex
`define OPCODE_CCC     7'b11100_11      // exx, csrxx

// configuration file

`include "../rtl/config.vh"

module darkriscv
//#(
//    parameter [31:0] RESET_PC = 0,
//    parameter [31:0] RESET_SP = 4096
//) 
(
    input             CLK,   // clock
    input             RES,   // reset
    input             HLT,   // halt
    
`ifdef __THREADING__    
    input             IREQ,  // irq req
`endif    

    input      [31:0] INSTR_DATA, // instruction data bus
    output     [31:0] INSTR_ADDR, // instruction addr bus
    
    input      [31:0] DATA_INPUT, // data bus (input)
    output     [31:0] DATA_OUTPUT, // data bus (output)
    output     [31:0] DATA_ADDR, // addr bus
    
	output     [ 3:0] BYTE_EN,   // byte enable (selects which bytes are load/stored from/to mem)
    
    output            WR_EN,    // write enable
    output            RD_EN,    // read enable 
    
    output [3:0]  DEBUG      // old-school osciloscope based debug! :)
);

    // dummy 32-bit words w/ all-0s and all-1s: 

    wire [31:0] ALL_ZEROES  = 0;
    wire [31:0] ALL_ONES  = -1;

`ifdef __THREADING__
    reg XMODE = 0;     // 0 = user, 1 = exception
`endif
    
    // pre-decode: INSTR_DATA is break apart as described in the RV32I specification

    reg [31:0] REG_INSTR_DATA;

    reg IS_INSTR_LUI, IS_INSTR_AUIPC, IS_INSTR_JAL, IS_INSTR_JALR, IS_INSTR_BCC, IS_INSTR_LCC, IS_INSTR_SCC, IS_INSTR_MCC, IS_INSTR_RCC, IS_INSTR_MAC; //, IS_INSTR_FCC, IS_INSTR_CCC;

    reg [31:0] sign_ext_imm;
    reg [31:0] unsign_ext_imm;

    always@(posedge CLK)
    begin        
        if(!HLT)
        begin
            REG_INSTR_DATA <= /*RES ? { ALL_ZEROES[31:12], 5'd2, ALL_ZEROES[6:0] } : HLT ? REG_INSTR_DATA : */INSTR_DATA;
            
            IS_INSTR_LUI   <= /*RES ? 0 : HLT ? IS_INSTR_LUI   : */INSTR_DATA[6:0]==`OPCODE_LUI;
            IS_INSTR_AUIPC <= /*RES ? 0 : HLT ? IS_INSTR_AUIPC : */INSTR_DATA[6:0]==`OPCODE_AUIPC;
            IS_INSTR_JAL   <= /*RES ? 0 : HLT ? IS_INSTR_JAL   : */INSTR_DATA[6:0]==`OPCODE_JAL;
            IS_INSTR_JALR  <= /*RES ? 0 : HLT ? IS_INSTR_JALR  : */INSTR_DATA[6:0]==`OPCODE_JALR;        

            IS_INSTR_BCC   <= /*RES ? 0 : HLT ? IS_INSTR_BCC   : */INSTR_DATA[6:0]==`OPCODE_BCC;
            IS_INSTR_LCC   <= /*RES ? 0 : HLT ? IS_INSTR_LCC   : */INSTR_DATA[6:0]==`OPCODE_LCC;
            IS_INSTR_SCC   <= /*RES ? 0 : HLT ? IS_INSTR_SCC   : */INSTR_DATA[6:0]==`OPCODE_SCC;
            IS_INSTR_MCC   <= /*RES ? 0 : HLT ? IS_INSTR_MCC   : */INSTR_DATA[6:0]==`OPCODE_MCC;

            IS_INSTR_RCC   <= /*RES ? 0 : HLT ? IS_INSTR_RCC   : */INSTR_DATA[6:0]==`OPCODE_RCC;
            IS_INSTR_MAC   <= /*RES ? 0 : HLT ? IS_INSTR_RCC   : */INSTR_DATA[6:0]==`OPCODE_MAC;
            //IS_INSTR_FCC   <= RES ? 0 : HLT ? IS_INSTR_FCC   : INSTR_DATA[6:0]==`OPCODE_FCC;
            //IS_INSTR_CCC   <= RES ? 0 : HLT ? IS_INSTR_CCC   : INSTR_DATA[6:0]==`OPCODE_CCC;

            // sign extended immediate, according to the instruction type:          
            sign_ext_imm  <= /*RES ? 0 : HLT ? sign_ext_imm :*/
                     INSTR_DATA[6:0]==`OPCODE_SCC ? { INSTR_DATA[31] ? ALL_ONES[31:12]:ALL_ZEROES[31:12], INSTR_DATA[31:25],INSTR_DATA[11:7] } : // s-type
                     INSTR_DATA[6:0]==`OPCODE_BCC ? { INSTR_DATA[31] ? ALL_ONES[31:13]:ALL_ZEROES[31:13], INSTR_DATA[31],INSTR_DATA[7],INSTR_DATA[30:25],INSTR_DATA[11:8],ALL_ZEROES[0] } : // b-type
                     INSTR_DATA[6:0]==`OPCODE_JAL ? { INSTR_DATA[31] ? ALL_ONES[31:21]:ALL_ZEROES[31:21], INSTR_DATA[31], INSTR_DATA[19:12], INSTR_DATA[20], INSTR_DATA[30:21], ALL_ZEROES[0] } : // j-type
                     INSTR_DATA[6:0]==`OPCODE_LUI||
                     INSTR_DATA[6:0]==`OPCODE_AUIPC ? { INSTR_DATA[31:12], ALL_ZEROES[11:0] } : // u-type
											{ INSTR_DATA[31] ? ALL_ONES[31:12]:ALL_ZEROES[31:12], INSTR_DATA[31:20] }; // i-type, l-type
            // non-sign extended immediate, according to the instruction type:

            unsign_ext_imm  <= /*RES ? 0: HLT ? unsign_ext_imm :*/
                     INSTR_DATA[6:0]==`OPCODE_SCC ? { ALL_ZEROES[31:12], INSTR_DATA[31:25],INSTR_DATA[11:7] } : // s-type
                     INSTR_DATA[6:0]==`OPCODE_BCC ? { ALL_ZEROES[31:13], INSTR_DATA[31],INSTR_DATA[7],INSTR_DATA[30:25],INSTR_DATA[11:8],ALL_ZEROES[0] } : // b-type
                     INSTR_DATA[6:0]==`OPCODE_JAL ? { ALL_ZEROES[31:21], INSTR_DATA[31], INSTR_DATA[19:12], INSTR_DATA[20], INSTR_DATA[30:21], ALL_ZEROES[0] } : // j-type
                     INSTR_DATA[6:0]==`OPCODE_LUI||
                     INSTR_DATA[6:0]==`OPCODE_AUIPC ? { INSTR_DATA[31:12], ALL_ZEROES[11:0] } : // u-type
											{ ALL_ZEROES[31:12], INSTR_DATA[31:20] }; // i-type, l-type
        end
    end

    // decode: after REG_INSTR_DATA
`ifdef __3STAGE__
    reg [1:0] flush_instr_pipe = -1;  // flush instruction pipeline
`else
    reg flush_instr_pipe = -1;  // flush instruction pipeline
`endif

`ifdef __THREADING__    
	error
`else

    `ifdef __RV32E__    
    
        reg [3:0] RESMODE = 0;
    
        wire [3:0] DPTR   = RES ? RESMODE : REG_INSTR_DATA[10: 7]; // set SP_RESET when RES==1
        wire [3:0] S1PTR  = REG_INSTR_DATA[18:15];
        wire [3:0] S2PTR  = REG_INSTR_DATA[23:20];
    `else
        reg [4:0] RESMODE = 0;
    
        wire [4:0] DPTR   = RES ? RESMODE : REG_INSTR_DATA[11: 7]; // set SP_RESET when RES==1
        wire [4:0] S1PTR  = REG_INSTR_DATA[19:15];
        wire [4:0] S2PTR  = REG_INSTR_DATA[24:20];    
    `endif

    wire [6:0] OPCODE = flush_instr_pipe ? 0 : REG_INSTR_DATA[6:0];
    wire [2:0] FCT3   = REG_INSTR_DATA[14:12];
    wire [6:0] FCT7   = REG_INSTR_DATA[31:25];

`endif /* __THREADING__ */
	   
    // main opcode decoder:
                                
    wire    OPCODE_LUI = flush_instr_pipe ? 0 : IS_INSTR_LUI;   // OPCODE==7'b0110111;
    wire  OPCODE_AUIPC = flush_instr_pipe ? 0 : IS_INSTR_AUIPC; // OPCODE==7'b0010111;
    wire    OPCODE_JAL = flush_instr_pipe ? 0 : IS_INSTR_JAL;   // OPCODE==7'b1101111;
    wire   OPCODE_JALR = flush_instr_pipe ? 0 : IS_INSTR_JALR;  // OPCODE==7'b1100111;
    
    wire    OPCODE_BCC = flush_instr_pipe ? 0 : IS_INSTR_BCC; // OPCODE==7'b1100011; //FCT3
    wire    OPCODE_LCC = flush_instr_pipe ? 0 : IS_INSTR_LCC; // OPCODE==7'b0000011; //FCT3
    wire    OPCODE_SCC = flush_instr_pipe ? 0 : IS_INSTR_SCC; // OPCODE==7'b0100011; //FCT3
    wire    OPCODE_MCC = flush_instr_pipe ? 0 : IS_INSTR_MCC; // OPCODE==7'b0010011; //FCT3
    
    wire    OPCODE_RCC = flush_instr_pipe ? 0 : IS_INSTR_RCC; // OPCODE==7'b0110011; //FCT3
    wire    OPCODE_MAC = flush_instr_pipe ? 0 : IS_INSTR_MAC; // OPCODE==7'b0110011; //FCT3
    //wire    OPCODE_FCC = flush_instr_pipe ? 0 : IS_INSTR_FCC; // OPCODE==7'b0001111; //FCT3
    //wire    OPCODE_CCC = flush_instr_pipe ? 0 : IS_INSTR_CCC; // OPCODE==7'b1110011; //FCT3

`ifdef __THREADING__
	error
`else
`ifdef __3STAGE__
    reg [31:0] NXPC2;       // 32-bit program counter t+2
`endif
    reg [31:0] NXPC;        // 32-bit program counter t+1
    reg [31:0] PC;		    // 32-bit program counter t+0

    `ifdef __RV32E__
		reg [31:0] RG [0:15];	// general-purpose 16x32-bit registers (src)
    `else
		reg [31:0] RG [0:31];	// general-purpose 32x32-bit registers (src)

    `endif
/*
    integer i; 
    initial 
    for(i=0;i!=32;i=i+1) 
    begin
        RG[i] = 0; // makes the simulation looks better!
    end
*/
`endif /* __THREADING__ */

    // source-1 and source-2 register selection

    wire signed   [31:0] S1REG = RG[S1PTR];
	wire signed   [31:0] S2REG = RG[S2PTR];
    
    wire          [31:0] U1REG = RG[S1PTR];
	wire          [31:0] U2REG = RG[S2PTR];
    
	// L-group (load) of instructions (OPCODE==7'b0000011)

    wire [31:0] LDATA = FCT3==0||FCT3==4 ? ( DATA_ADDR[1:0]==3 ? { FCT3==0&&DATA_INPUT[31] ? ALL_ONES[31: 8]:ALL_ZEROES[31: 8] , DATA_INPUT[31:24] } :
                                             DATA_ADDR[1:0]==2 ? { FCT3==0&&DATA_INPUT[23] ? ALL_ONES[31: 8]:ALL_ZEROES[31: 8] , DATA_INPUT[23:16] } :
                                             DATA_ADDR[1:0]==1 ? { FCT3==0&&DATA_INPUT[15] ? ALL_ONES[31: 8]:ALL_ZEROES[31: 8] , DATA_INPUT[15: 8] } :
                                                             { FCT3==0&&DATA_INPUT[ 7] ? ALL_ONES[31: 8]:ALL_ZEROES[31: 8] , DATA_INPUT[ 7: 0] } ):
                        FCT3==1||FCT3==5 ? ( DATA_ADDR[1]==1   ? { FCT3==1&&DATA_INPUT[31] ? ALL_ONES[31:16]:ALL_ZEROES[31:16] , DATA_INPUT[31:16] } :
                                                             { FCT3==1&&DATA_INPUT[15] ? ALL_ONES[31:16]:ALL_ZEROES[31:16] , DATA_INPUT[15: 0] } ) :
                                             DATA_INPUT;

	// S-group (store) of instructions (OPCODE==7'b0100011)

    wire [31:0] SDATA = FCT3==0 ? ( DATA_ADDR[1:0]==3 ? { U2REG[ 7: 0], ALL_ZEROES [23:0] } : 
                                    DATA_ADDR[1:0]==2 ? { ALL_ZEROES [31:24], U2REG[ 7:0], ALL_ZEROES[15:0] } : 
                                    DATA_ADDR[1:0]==1 ? { ALL_ZEROES [31:16], U2REG[ 7:0], ALL_ZEROES[7:0] } :
                                                    { ALL_ZEROES [31: 8], U2REG[ 7:0] } ) :
                        FCT3==1 ? ( DATA_ADDR[1]==1   ? { U2REG[15: 0], ALL_ZEROES [15:0] } :
                                                    { ALL_ZEROES [31:16], U2REG[15:0] } ) :
                                    U2REG;

    // C-group not implemented yet!
    
    wire [31:0] CDATA = 0;	// status register istructions not implemented yet

    // RM-group of instructions (OPCODEs==7'b0010011/7'b0110011), merged! src=immediate(M)/register(R)

    wire signed [31:0] S2REGX = IS_INSTR_MCC ? sign_ext_imm : S2REG;
    wire        [31:0] U2REGX = IS_INSTR_MCC ? unsign_ext_imm : U2REG;

    wire [31:0] RMDATA = FCT3==7 ? U1REG&S2REGX :
                         FCT3==6 ? U1REG|S2REGX :
                         FCT3==4 ? U1REG^S2REGX :
                         FCT3==3 ? U1REG<U2REGX?1:0 : // unsigned
                         FCT3==2 ? S1REG<S2REGX?1:0 : // signed
                         FCT3==0 ? (IS_INSTR_RCC&&FCT7[5] ? U1REG-U2REGX : U1REG+S2REGX) :
                         FCT3==1 ? U1REG<<U2REGX[4:0] :                         
                         //FCT3==5 ? 
`ifdef MODEL_TECH        
                         FCT7[5]==0||U1REG[31]==0 ? U1REG>>U2REGX[4:0] : -((-U1REG)>>U2REGX[4:0]; // workaround for modelsim
`else
                         FCT7[5] ? U1REG>>>U2REGX[4:0] : U1REG>>U2REGX[4:0]; // (FCT7[5] ? U1REG>>>U2REG[4:0] : U1REG>>U2REG[4:0])
`endif                        

`ifdef __MAC16X16__

    // OPCODE_MAC instruction rd += s1*s2 (OPCODE==7'b1111111)
    // 
    // 0000000 01100 01011 100 01100 0110011 xor a2,a1,a2
    // 0000000 01010 01100 000 01010 0110011 add a0,a2,a0
    // 0000000 01100 01011 000 01010 1111111 mac a0,a1,a2
    // 
    // 0000 0000 1100 0101 1000 0101 0111 1111 = 00c5857F

    wire signed [15:0] K1TMP = S1REG[15:0];
    wire signed [15:0] K2TMP = S2REG[15:0];
    wire signed [31:0] KDATA = K1TMP*K2TMP;

`endif

    // J/B-group of instructions (OPCODE==7'b1100011)
    
    wire BMUX       = OPCODE_BCC==1 && (
                          FCT3==4 ? S1REG< S2REG : // blt
                          FCT3==5 ? S1REG>=S2REG : // bge
                          FCT3==6 ? U1REG< U2REG : // bltu
                          FCT3==7 ? U1REG>=U2REG : // bgeu
                          FCT3==0 ? U1REG==U2REG : // beq
                          FCT3==1 ? U1REG!=U2REG : // bne
                                    0);

    wire        JREQ = (OPCODE_JAL||OPCODE_JALR||BMUX);
    wire [31:0] JVAL = sign_ext_imm + (OPCODE_JALR ? U1REG : PC);

`ifdef __PERFMETER__
	error
`endif

	/* Instr execute */
    always@(posedge CLK)
    begin
		/* in darksocv.v reset RES=1 stayes 2^7 cycles */
        RESMODE <= RESMODE +1;

`ifdef __3STAGE__
	    flush_instr_pipe <= RES ? 2 : HLT ? flush_instr_pipe :        // reset and halt                              
	                       flush_instr_pipe ? flush_instr_pipe-1 :                           
	                       (OPCODE_JAL||OPCODE_JALR||BMUX) ? 2 : 0;  // flush the pipeline!
`else
        flush_instr_pipe <= RES ? 1 : HLT ? flush_instr_pipe :        // reset and halt
                       (OPCODE_JAL||OPCODE_JALR||BMUX);  // flush the pipeline!
`endif

		/* if RES==1 then DPTR=RESMODE and the register x2 is SP */
`ifdef __RV32E__
        RG[DPTR] <=   RES ? (RESMODE[3:0]==2 ? `__RESETSP__ : 0)  :        // reset sp
`else
        RG[DPTR] <=   RES ? (RESMODE[4:0]==2 ? `__RESETSP__ : 0)  :        // reset sp
`endif
                       HLT ? RG[DPTR] :        // halt
                     !DPTR ? 0 :                // x0 = 0, always!
                     OPCODE_AUIPC ? PC+sign_ext_imm :
                      OPCODE_JAL||
                      OPCODE_JALR ? NXPC :
                       OPCODE_LUI ? sign_ext_imm :
                       OPCODE_LCC ? LDATA :
                  OPCODE_MCC||OPCODE_RCC ? RMDATA:
`ifdef __MAC16X16__                  
                       OPCODE_MAC ? RG[DPTR]+KDATA :
`endif
                       //OPCODE_MCC ? MDATA :
                       //OPCODE_RCC ? RDATA : 
                       //OPCODE_CCC ? CDATA : 
                             RG[DPTR];

`ifdef __3STAGE__

`ifdef __THREADING__
	error
`else /* __THREADING__ */
        NXPC <= /*RES ? `__RESETPC__ :*/ HLT ? NXPC : NXPC2;
	
	    NXPC2 <=  RES ? `__RESETPC__ : HLT ? NXPC2 :   // reset and halt
	                 JREQ ? JVAL :                    // jmp/bra
	                        NXPC2+4;                   // normal flow

`endif /* __THREADING__ */

`else /* __3STAGE__ */
        NXPC <= RES ? `__RESETPC__ : HLT ? NXPC :   // reset and halt
              JREQ ? JVAL :                   // jmp/bra
                     NXPC+4;                   // normal flow
`endif /* __3STAGE__ */
        PC   <= /*RES ? `__RESETPC__ :*/ HLT ? PC : NXPC; // current program counter
    end

    // IO and memory interface

    assign DATA_OUTPUT = SDATA; // OPCODE_SCC ? SDATA : 0;
    assign DATA_ADDR = U1REG + sign_ext_imm; // (OPCODE_SCC||OPCODE_LCC) ? U1REG + sign_ext_imm : 0;

    assign RD_EN = OPCODE_LCC;
    assign WR_EN = OPCODE_SCC;
    
    // based in the Scc and Lcc   

    assign BYTE_EN = FCT3==0||FCT3==4 ? ( DATA_ADDR[1:0]==3 ? 4'b1000 : // sb/lb
                                     DATA_ADDR[1:0]==2 ? 4'b0100 : 
                                     DATA_ADDR[1:0]==1 ? 4'b0010 :
                                                     4'b0001 ) :
                FCT3==1||FCT3==5 ? ( DATA_ADDR[1]==1   ? 4'b1100 : // sh/lh
                                                     4'b0011 ) :
                                                     4'b1111; // sw/lw

`ifdef __3STAGE__
`ifdef __THREADING__
	error
`else
    assign INSTR_ADDR = NXPC2;
`endif    
`else /* __3STAGE__ */
    assign INSTR_ADDR = NXPC;
`endif /* __3STAGE__ */

    assign DEBUG = { RES, |flush_instr_pipe, WR_EN, RD_EN };

endmodule
