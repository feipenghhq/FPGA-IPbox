///////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 by Heqing Huang (feipenghhq@gamil.com)
//
// Project Name: N/A
// Module Name: fwft_fifo
//
// Author: Heqing Huang
// Date Created: 10/28/2020
//
// ================== Description ==================
//
// First Word Fall Through FIFO.
//
///////////////////////////////////////////////////////////////////////////////

module fwft_fifo #(
parameter DWIDTH = 32,          // Data width
parameter DEPTH  = 4
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

localparam AWIDTH = $clog2(DEPTH);

reg [DWIDTH-1:0]  mem[2**AWIDTH-1:0];   // Only this style works in vivado.
reg [AWIDTH:0]    rdptr;                // FIFO read pointer
reg [AWIDTH:0]    wtptr;                // FIFO write pointer
reg [DWIDTH-1:0]  data_out;
reg [DWIDTH-1:0]  data_buffer;
wire              ren;
wire              wen;
wire [AWIDTH-1:0] mem_rdptr;          // the actual memory read pointer

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
            rdptr <= rdptr + 1'b1;
        end

        if (!full && write)
        begin
            wtptr <= wtptr + 1'b1;
        end
    end
end

assign full  = ((wtptr - rdptr) == DEPTH) ? 1'b1 : 1'b0;
assign empty = ((wtptr - rdptr) == 0)     ? 1'b1 : 1'b0;

//=====================
// FWFT logic
//=====================

always @(posedge clk) begin
    // Also put the first write data into data buffer when FIFO is empty
    if (wen && empty) data_buffer <= din;
    // pop the next data from the pre-read memory location
    else if (ren)     data_buffer <= data_out;
end

assign dout = data_buffer;

//=====================
// RAM R/W logic
//=====================
assign wen = !full & write;
assign ren = !empty & read;

// for the FWFT FIFO, data_buffer hold the current data on top so read the next location in the memory
assign mem_rdptr = rdptr[AWIDTH-1:0] + 1'b1;

always @(posedge clk)
begin
    if (ren) data_out <= mem[mem_rdptr];
    if (wen) mem[wtptr[AWIDTH-1:0]] <= din;
end

endmodule
