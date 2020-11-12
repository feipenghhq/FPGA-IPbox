///////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 by Heqing Huang (feipenghhq@gamil.com)
//
// Project Name: N/A
// Module Name: fwft_async_fifo
//
// Author: Heqing Huang
// Date Created: 11/07/2020
//
// ================== Description ==================
//
// Revision 1.0:
//  First Word Fall Through ASYNC FIFO.
//
///////////////////////////////////////////////////////////////////////////////

module fwft_async_fifo #(
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

wire                read_int;
wire                empty_int;
wire                almost_empty_int;
reg                 prefetched;


// =========================================
// FWFT logic
// =========================================

// because our async-FIFO already has a output register to store value,
// we can read it and prefetch the data into the output register.
// read when FIFO is not empty and we have not prefetched
// or read when FIFO is not empty and there is a new read request
assign read_int = (~prefetched & ~empty_int) | (prefetched & ~empty_int & read);

// If we are have not prefetched anything than we must be empty
assign empty = ~prefetched;

// use the original almost_empty, but actually we have 1 more item away from the true almost empty.
assign almost_empty = almost_empty_int;

always @(posedge clk_rd) begin
    if (rst_rd) begin
        prefetched <= 1'b0;
    end
    else begin
        prefetched <= (~prefetched & read_int) | (prefetched & read & read_int) | (prefetched & ~read);
    end
end

// =========================================
// The regular async FIFO
// =========================================
async_fifo #(
    .DWIDTH(DWIDTH),
    .DEPTH(DEPTH),
    .AMOST_FULL(AMOST_FULL),
    .AMOST_EMPTY(AMOST_EMPTY)
) async_fifo (
    .rst_rd         (rst_rd),
    .clk_rd         (clk_rd),
    .read           (read_int),
    .dout           (dout),
    .empty          (empty_int),
    .almost_empty   (almost_empty_int),
    .rst_wr         (rst_wr),
    .clk_wr         (clk_wr),
    .din            (din),
    .write          (write),
    .full           (full),
    .almost_full    (almost_full)
);

endmodule