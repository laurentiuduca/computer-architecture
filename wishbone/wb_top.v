// Modifications by Laurentiu-Cristian Duca
// laurentiu [dot] duca [at] gmail [dot] com
// 2020/03/24

/////////////////////////////////////////////////////////////////////
////                                                             ////
//// Wishbone Creator                                            ////
//// Copyright (C) 2004 Daniel Wiklund, Linköping University     ////
////                                                             ////
//// This source file may be used and distributed without        ////
//// restriction provided that this copyright statement is not   ////
//// removed from the file and that any derivative work contains ////
//// the original copyright notice and the associated disclaimer.////
////                                                             ////
////     THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     ////
//// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   ////
//// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   ////
//// FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      ////
//// OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         ////
//// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    ////
//// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   ////
//// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        ////
//// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  ////
//// LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  ////
//// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  ////
//// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         ////
//// POSSIBILITY OF SUCH DAMAGE.                                 ////
////                                                             ////
/////////////////////////////////////////////////////////////////////

`include "wb_def.v"

module wb_top(
  clk_i, rst_i,

  // Master 0 Interface
  m0_dat_i, m0_dat_o, m0_adr_i, m0_sel_i,
  m0_we_i,  m0_cyc_i, m0_stb_i, m0_cab_i,
  m0_ack_o, m0_err_o, m0_rty_o, m0_cti_i,
  m0_bte_i,

  // Master 1 Interface
  m1_dat_i, m1_dat_o, m1_adr_i, m1_sel_i,
  m1_we_i,  m1_cyc_i, m1_stb_i, m1_cab_i,
  m1_ack_o, m1_err_o, m1_rty_o, m1_cti_i,
  m1_bte_i,

  // Slave 0 Interface
  s0_dat_o, s0_dat_i, s0_adr_o, s0_sel_o,
  s0_we_o,  s0_cyc_o, s0_stb_o, s0_cab_o,
  s0_ack_i, s0_err_i, s0_rty_i, s0_cti_o,
  s0_bte_o,

  // Slave 1 Interface
  s1_dat_o, s1_dat_i, s1_adr_o, s1_sel_o,
  s1_we_o,  s1_cyc_o, s1_stb_o, s1_cab_o,
  s1_ack_i, s1_err_i, s1_rty_i, s1_cti_o,
  s1_bte_o,

  // Test/debug output
  grant_o
  );

parameter s0_addr_width = 8;
parameter s0_addr = 8'h40;
parameter s1_addr_width = 8;
parameter s1_addr = 8'h90;

// Syscon interface
input            clk_i, rst_i;
output [`ms-1:0] grant_o;

// Master 0 Interface
input  [`dw-1:0]    m0_dat_i;
output [`dw-1:0]    m0_dat_o;
input  [`aw-1:0]    m0_adr_i;
input  [`selw-1:0]  m0_sel_i;
input               m0_we_i;
input               m0_cyc_i;
input               m0_stb_i;
input               m0_cab_i;
output              m0_ack_o;
output              m0_rty_o;
output              m0_err_o;
input  [2:0]        m0_cti_i;
input  [1:0]        m0_bte_i;

// Master 1 Interface
input  [`dw-1:0]    m1_dat_i;
output [`dw-1:0]    m1_dat_o;
input  [`aw-1:0]    m1_adr_i;
input  [`selw-1:0]  m1_sel_i;
input               m1_we_i;
input               m1_cyc_i;
input               m1_stb_i;
input               m1_cab_i;
output              m1_ack_o;
output              m1_rty_o;
output              m1_err_o;
input  [2:0]        m1_cti_i;
input  [1:0]        m1_bte_i;

// Slave 0 Interface
output [`dw-1:0]    s0_dat_o;
input  [`dw-1:0]    s0_dat_i;
output [`aw-1:0]    s0_adr_o;
output [`selw-1:0]  s0_sel_o;
output              s0_we_o;
output              s0_cyc_o;
output              s0_stb_o;
output              s0_cab_o;
input               s0_ack_i;
input               s0_rty_i;
input               s0_err_i;
output [2:0]        s0_cti_o;
output [1:0]        s0_bte_o;

// Slave 1 Interface
output [`dw-1:0]    s1_dat_o;
input  [`dw-1:0]    s1_dat_i;
output [`aw-1:0]    s1_adr_o;
output [`selw-1:0]  s1_sel_o;
output              s1_we_o;
output              s1_cyc_o;
output              s1_stb_o;
output              s1_cab_o;
input               s1_ack_i;
input               s1_rty_i;
input               s1_err_i;
output [2:0]        s1_cti_o;
output [1:0]        s1_bte_o;

// Master and slave input/output signals for mux bus
wire [`ms-1:0]    gnt;
wire [`ss-1:0]    ssel;
wire [`ss-1:0]    m0_ssel;
wire [`ss-1:0]    m1_ssel;
wire [`sbusw-1:0] s_signal;
wire [`mbusw-1:0] m_signal;
// Master 0 inputs
wire [`mbusw-1:0] m0_signal;
assign m0_signal = {m0_adr_i, m0_dat_i, m0_sel_i, m0_we_i, m0_cyc_i, m0_stb_i, m0_cab_i, m0_cti_i, m0_bte_i};
// Master 0 outputs
assign m0_dat_o = s_signal[34:3];
assign m0_ack_o = s_signal[2] & gnt[0];
assign m0_err_o = s_signal[1] & gnt[0];
assign m0_rty_o = s_signal[0] & gnt[0];

// Master 1 inputs
wire [`mbusw-1:0] m1_signal;
assign m1_signal = {m1_adr_i, m1_dat_i, m1_sel_i, m1_we_i, m1_cyc_i, m1_stb_i, m1_cab_i, m1_cti_i, m1_bte_i};
// Master 1 outputs
assign m1_dat_o = s_signal[34:3];
assign m1_ack_o = s_signal[2] & gnt[1];
assign m1_err_o = s_signal[1] & gnt[1];
assign m1_rty_o = s_signal[0] & gnt[1];

// Slave 0 inputs
wire [`sbusw-1:0] s0_signal;
assign s0_signal = {s0_dat_i, s0_ack_i, s0_err_i, s0_rty_i};
// Slave 0 outputs
assign s0_adr_o = m_signal[76:45];
assign s0_dat_o = m_signal[44:13];
assign s0_sel_o = m_signal[12:9];
assign s0_we_o  = m_signal[8];
assign s0_cyc_o = m_signal[7];
assign s0_stb_o = m_signal[6] & m_signal[7] & ssel[0];
assign s0_cab_o = m_signal[5];
assign s0_cti_o = m_signal[4:2];
assign s0_bte_o = m_signal[1:0];

// Slave 1 inputs
wire [`sbusw-1:0] s1_signal;
assign s1_signal = {s1_dat_i, s1_ack_i, s1_err_i, s1_rty_i};
// Slave 1 outputs
assign s1_adr_o = m_signal[76:45];
assign s1_dat_o = m_signal[44:13];
assign s1_sel_o = m_signal[12:9];
assign s1_we_o  = m_signal[8];
assign s1_cyc_o = m_signal[7];
assign s1_stb_o = m_signal[6] & m_signal[7] & ssel[1];
assign s1_cab_o = m_signal[5];
assign s1_cti_o = m_signal[4:2];
assign s1_bte_o = m_signal[1:0];

assign m_signal = gnt[0] ? m0_signal :
				  m1_signal;

assign s_signal = ssel[0] ? s0_signal :
				  ssel[1] ?	s1_signal : s0_signal;

assign ssel     = gnt[0] ? m0_ssel :
				  gnt[1] ? m1_ssel : 10'b0;

assign m0_ssel[0] = (m0_adr_i[s0_addr_width-1:0] == s0_addr);
assign m0_ssel[1] = (m0_adr_i[s1_addr_width-1:0] == s1_addr);
assign m1_ssel[0] = (m1_adr_i[s0_addr_width-1:0] == s0_addr);
assign m1_ssel[1] = (m1_adr_i[s1_addr_width-1:0] == s1_addr);

wb_arb arb(
  .clk_i(clk_i),
  .rst_i(rst_i),
  .req_i({m1_cyc_i, m0_cyc_i}),
  .gnt_o(gnt)
);

assign grant_o = gnt;

endmodule
