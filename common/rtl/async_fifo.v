///////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 by Heqing Huang (feipenghhq@gamil.com)
//
// Project Name: N/A
// Module Name: async_fifo
//
// Author: Heqing Huang
// Date Created: 11/07/2020
//
// ================== Description ==================
//
// Revision 1.0:
//  A very basic ASYNC FIFO.
//  Read latency is 1.
//  Provides fixed almost full and almost empty indicator
//
///////////////////////////////////////////////////////////////////////////////

module async_fifo #(
parameter DWIDTH = 32,          // Data width
parameter DEPTH = 16,           // FIFO depth
parameter AMOST_FULL = 4,       // Almost full threshold
parameter AMOST_EMPTY = 4       // Almost full threshold
) (
// Read side
input               rst_rd,
input               clk_rd,
input               read,
output [DWIDTH-1:0] dout,
output              empty,
output              almost_empty,
// Write side
input               rst_wr,
input               clk_wr,
input [DWIDTH-1:0]  din,
input               write,
output              full,
output              almost_full
);

localparam AWIDTH = $clog2(DEPTH);

//========================
// Signals
//========================

reg [DWIDTH-1:0]    mem[2**AWIDTH-1:0];   // Only this style works in vivado.

// Read side
reg [DWIDTH-1:0]    data_out;
reg [AWIDTH:0]      rdptr_bin;
reg [AWIDTH:0]      rdptr_gry;
reg  [AWIDTH:0]     wrptr_bin_clk_rd;
wire                ren;
wire [AWIDTH:0]     wrptr_gry_clk_rd;
wire [AWIDTH-1:0]   rd_addr;

// Write side
reg [AWIDTH:0]      wrptr_bin;
reg [AWIDTH:0]      wrptr_gry;
reg  [AWIDTH:0]     rdptr_bin_clk_wr;
wire                wen;
wire [AWIDTH:0]     rdptr_gry_clk_wr;
wire [AWIDTH-1:0]   wr_addr;

//====================================
// FIFO control logic - Read side
//====================================

// CDC logic
genvar i;
generate
    for (i = 0; i <= AWIDTH; i = i + 1) begin
        dsync wrptr_gry_dsync(.D(wrptr_gry[i]), .Q(wrptr_gry_clk_rd[i]), .rst(rst_rd), .clk(clk_rd));
    end
endgenerate

// control
assign ren = !empty & read;
assign empty = ((wrptr_bin_clk_rd - rdptr_bin) == 0) ? 1'b1 : 1'b0;
assign almost_empty = ((wrptr_bin_clk_rd - rdptr_bin) <= AMOST_EMPTY) ? 1'b1 : 1'b0;

// read pointer
always @(posedge clk_rd)
begin
    if (rst_rd) begin
        rdptr_bin <= 'b0;
        rdptr_gry <= 'b0;
        wrptr_bin_clk_rd <= 'b0;
    end
    else begin
        wrptr_bin_clk_rd <= grey2bin(wrptr_gry_clk_rd);
        rdptr_gry <= bin2grey(rdptr_bin);
        if (ren) rdptr_bin <= rdptr_bin + 1'b1;
    end
end

//====================================
// FIFO control logic - Write side
//====================================

// CDC logic
genvar j;
generate
    for (j = 0; j <= AWIDTH; j = j + 1) begin
        dsync wrptr_gry_dsync(.D(rdptr_gry[j]), .Q(rdptr_gry_clk_wr[j]), .rst(rst_wr), .clk(clk_wr));
    end
endgenerate

// ----vvvvv-----
// Need to put the substraction value into another variable before the comparsion
// Something like this will fail to set full signal in either iverilog or modelsim simulator
// assign full  = ((wrptr_bin - rdptr_bin_clk_wr) == DEPTH) ? 1'b1 : 1'b0;
//
wire [AWIDTH:0] wrptr_minus_rdptr;
assign wrptr_minus_rdptr = wrptr_bin - rdptr_bin_clk_wr;
assign full  = (wrptr_minus_rdptr == DEPTH[AWIDTH:0]) ? 1'b1 : 1'b0;
assign almost_full  = (wrptr_minus_rdptr >= (DEPTH[AWIDTH:0] - AMOST_FULL[AWIDTH:0])) ? 1'b1 : 1'b0;
// ----^^^^-----

assign wen = !full & write;

// write pointer
always @(posedge clk_wr)
begin
    if (rst_wr) begin
        wrptr_bin <= 'b0;
        wrptr_gry <= 'b0;
        rdptr_bin_clk_wr <= 'b0;
    end
    else
    begin
        wrptr_gry <= bin2grey(wrptr_bin);
        rdptr_bin_clk_wr <= grey2bin(rdptr_gry_clk_wr);
        if (!full && write) wrptr_bin <= wrptr_bin + 1'b1;
    end
end

//=====================
// RAM control logic
//=====================

assign rd_addr = rdptr_bin[AWIDTH-1:0];
always @(posedge clk_rd)
begin
    if (ren)
    begin
        data_out <= mem[rd_addr];
    end
end

assign wr_addr = wrptr_bin[AWIDTH-1:0];
always @(posedge clk_wr)
begin
    if (wen)
    begin
        mem[wr_addr] <= din;
    end
end

assign dout = data_out;

// =====================
// Grey2Bin
// =====================
function [AWIDTH:0] grey2bin;
    input [AWIDTH:0] grey;
    integer b;
    begin
        grey2bin[AWIDTH] = grey[AWIDTH];
        for (b = AWIDTH - 1; b >= 0 ; b = b - 1)
            grey2bin[b] = grey[b] ^ grey2bin[b+1];
    end
endfunction

// =====================
// Bin2Grey
// =====================
function [AWIDTH:0] bin2grey;
    input [AWIDTH:0] bin;
    integer a;
    begin
        for (a = 0; a < AWIDTH; a = a + 1)
            bin2grey[a] = bin[a] ^ bin[a+1];
        bin2grey[AWIDTH] = bin[AWIDTH];
    end
endfunction

endmodule
