///////////////////////////////////////////////////////////////////////////////
//
// Project Name: N/A
// Module Name: fifo
//
// Author: Heqing Huang
// Date Created: 05/06/2019
//
// ================== Description ==================
//
// Revision 1.0:
//  Basic FIFO design with full/empty flag. No overflow/underflow error
//  checking. Read latency is 1.
// 
///////////////////////////////////////////////////////////////////////////////

module fifo #(
parameter DWIDTH = 32,          // Data width
parameter AWIDTH = 4            // Address width. Depth of the FIFO = 2^AWIDTH
) (
input               rst,
input               clk,
input               write,
input               read,
input [DWIDTH-1:0]  din,
output [DWIDTH-1:0] dout,
output              full,
output              empty
);

localparam DEPTH = 2**AWIDTH;

reg [DWIDTH-1:0]  mem[2**AWIDTH-1:0];   // Only this style works in vivado.
reg [AWIDTH:0]    rdptr;                // read pointer - use AWIDTH bit to avoid turn-around issue. only use AWIDTH-1 bit to retrive data
reg [AWIDTH:0]    wtptr;                // write pointer - use AWIDTH bit to avoid turn-around issue. only use AWIDTH-1 bit to retrive data
reg [DWIDTH-1:0]  data_out;             
wire              ren;                  
wire              wen;                  

//========================
// FIFO control logic
//========================
always @(posedge clk)
begin
    if (rst)
    begin
        rdptr <= 'b0;
        wtptr <= 'b0;
    end
    else
    begin
        if (!empty && read)
        begin
            rdptr <= rdptr + 1;
        end

        if (!full && write)
        begin
            wtptr <= wtptr + 1;
        end
    end
end

assign wen = !full & write;
assign ren = !empty & read;
assign full  = ((wtptr - rdptr) == DEPTH) ? 1'b1 : 1'b0;
assign empty = ((wtptr - rdptr) == 0)     ? 1'b1 : 1'b0;

//=====================
// RAM control logic
//=====================
always @(posedge clk)
begin
    if (ren)
    begin
        data_out <= mem[rdptr[AWIDTH-1:0]];
    end
    if (wen)
    begin
        mem[wtptr[AWIDTH-1:0]] <= din;
    end
end

assign dout = data_out;

endmodule