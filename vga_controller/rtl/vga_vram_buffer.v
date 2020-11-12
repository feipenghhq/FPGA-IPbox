///////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 by Heqing Huang (feipenghhq@gamil.com)
//
// Project Name: VGA
// Module Name: vga_vram_buffer
//
// Author: Heqing Huang
// Date Created: 11/06/2020
//
// ================== Description ==================
//
// This module implements the pixel buffer and also provides the logic to access
// the VRAM module.
// It has the following function:
//  1. An async-FIFO as the pixel buffer to the VRAM.
//  2. At the VGA side, read the async-FIFO to get the pixel data.
//  3. At the Core side, prefetch the VRAM content into FIFO buffer.
//
///////////////////////////////////////////////////////////////////////////////

//
// One Important note for the VRAM controller:
//
// Bcause we use the async-FIFO to buffer the VRAM data, it acts like a
// stream buffer and there is no address. VGA side will always assume
// that the next data it read from the FIFO is at the current address.
// This assumption is true as long as the write side writes the data
// at the correct address sequence.
//
// However, this convension break when the FIFO is empty and VGA is still
// reading. VGA can't stop so it will read the invalid data.
// And when FIFO becomes non-empty again, the data on the TOP of the FIFO
// is not the currect VGA data anymore.
//
// Ideally we should not hit this situation because we should make sure the
// VRAM read path get enough bandwidth to fetch the data.
//
// If this error does happen, then there is no way to recover for now except for
// resetting the vga controller
//


`include "vga.vh"

module vga_vram_buffer #(
parameter PWIDTH  = 8,      // pixel width
parameter LATENCY = 2,      // vram read latency
parameter BUFSIZE = 1 << $clog2(`HCNT),    // buffer size
parameter HWIDTH = $clog2(`HCNT),   // Fixed parameter
parameter VWIDTH = $clog2(`VCNT),   // Fixed parameter
parameter AWIDTH = HWIDTH + VWIDTH  // Fixed parameter
) (
// VGA side
input                   clk_vga,
input                   rst_vga,
input                   vga_rd,
input                   first_pixel, // indicate this read is the first pixel.
output [PWIDTH-1:0]     vga_pixel,
// Core side
input                   clk_core,
input                   rst_core,
input                   vram_busy,
output [AWIDTH-1:0]     vram_addr,
output                  vram_rd,
input [PWIDTH-1:0]      vram_data,
input                   vram_vld,
output                  out_sync
);

// =====================================
// Common signal/parameter
// =====================================
localparam AMOST_FULL = LATENCY + 1 + 1;    // Latency + current cycle + potential current write operation
localparam AMOST_EMPTY = 0;             // not really used

// =====================================
// VGA side
// =====================================

//
// We need to wait for the FIFO becomes non-empty then start the read process.
// This is to make sure we are in sync.
//
wire                buffer_empty;
wire                fifo_rd;
wire                first_rd_vld;   // indicate first read and buffer is not empty

reg                 in_sync;

always @(posedge clk_vga) begin
    if (rst_vga) in_sync <= 1'b0;
    else if (first_rd_vld) in_sync <= 1'b1;
end

assign first_rd_vld = vga_rd & first_pixel & ~buffer_empty;
assign out_sync = buffer_empty & vga_rd;
assign fifo_rd = (~buffer_empty & vga_rd & in_sync) | first_rd_vld;

// =====================================
// Core side
// =====================================

reg [HWIDTH-1:0] h_addr;
reg [VWIDTH-1:0] v_addr;

wire            buffer_almost_full;
wire            buffer_full;
wire            h_tick;
wire            v_tick;
wire            fifo_wr;

// we should not issue read request while we are in reset.
// This cause a bug in the design if we do so.
assign vram_rd = ~buffer_almost_full & ~vram_busy & ~rst_core;
assign vram_addr = {v_addr, h_addr};
assign fifo_wr = ~buffer_full & vram_vld;   // ideally vram buffer should never be full


assign h_tick = (h_addr == `HVA-1);
assign v_tick = (v_addr == `VVA-1);

// calculate the address
always @(posedge clk_core)
begin
    if (rst_core) begin
        h_addr <= 'b0;
        v_addr <= 'b0;
    end
    else if(vram_rd) begin
        if (h_tick) h_addr <= 'b0;
        else        h_addr <= h_addr + 1'b1;
        if (h_tick) begin
            if (v_tick) v_addr <= 'b0;
            else        v_addr <= v_addr + 1'b1;
        end
    end
end

// =====================================
// Async FIFO
// =====================================

fwft_async_fifo #(
    .DWIDTH(PWIDTH),
    .DEPTH(BUFSIZE),
    .AMOST_FULL(AMOST_FULL),
    .AMOST_EMPTY(AMOST_EMPTY)
) vram_buffer (
    .rst_rd         (rst_vga),
    .clk_rd         (clk_vga),
    .read           (fifo_rd),
    .dout           (vga_pixel),
    .empty          (buffer_empty),
    /* verilator lint_off PINCONNECTEMPTY */
    .almost_empty   (), // not used
    /* verilator lint_on PINCONNECTEMPTY */
    .rst_wr         (rst_core),
    .clk_wr         (clk_core),
    .din            (vram_data),
    .write          (fifo_wr),
    .full           (buffer_full),
    .almost_full    (buffer_almost_full)
);

endmodule