// Modifications by Laurentiu-Cristian Duca
// laurentiu [dot] duca [at] gmail [dot] com

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

module wb_arb(clk_i, rst_i, req_i, gnt_o);

input            clk_i;
input            rst_i;
input  [`ms-1:0] req_i;
output [`ms-1:0] gnt_o;

parameter [`gntw-1:0] grant0 = 3'h0,
                      grant1 = 3'h1;

reg [`gntw-1:0] state, next_state;

always @ (posedge clk_i)
  if (rst_i) state <= #1 grant0;
  else       state <= #1 next_state;

assign gnt_o[0] = (state == 3'h0);
assign gnt_o[1] = (state == 3'h1);

always @ (state or req_i) begin
  case(state)
    grant0:
      if (req_i[0]) next_state = grant0;
		else if (req_i[1]) next_state = grant1;
		else next_state = grant0;
    grant1:
      if (req_i[1]) next_state = grant1;
		else if (req_i[0]) next_state = grant0;
        else next_state = grant1;
  endcase
end

endmodule
