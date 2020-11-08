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
// A note about the re-sync logic:
//
// Bcause we use the async-FIFO to buffer the VRAM data, it ack like a
// stream buffer and there is no address. VGA side will always assume
// that the next data it read from the FIFO is at the current address.
// This assumption is true as long as the write side writes the data
// at the correct address sequence.
//
// However, this convension will be broken when the FIFO is empty.
// VGA side will still read the data since it can not stop. When
// The FIFO become non-empty again, the data on the TOP is actual
// the missed data, and if it's get read then it's not the correct
// pixel for that location.
//
// To deal with this situation, when FIFO become empty, we will clear
// the FIFO, refetch the data from the first location, and stop the VGA
// from reading the FIFO (by provide junk data unfortunately), and once VGA
// start from the new data, then we will resume the read.
//
// Ideally we should not hit this situation because we should make sure the
// VRAM read path get enough bandwidth to fetch the data. But if it happens
// for any reason, this re-sync logic will help to prevent the display being
// unaligned.
//
// FIXME: THIS FEATURE WILL BE IMPLEMENTED LATER AFTER COMPLETE BASIC FUNCTION
//


`include "vga.vh"

module vga_vram_buffer #(
parameter PWIDTH  = 8,      // pixel width
parameter LATENCY = 4,      // vram read latency
parameter HWIDTH = $clog2(`HCNT),   // Fixed parameter
parameter VWIDTH = $clog2(`VCNT),   // Fixed parameter
parameter AWIDTH = HWIDTH + VWIDTH  // Fixed parameter
) (
// VGA side
input                   clk_vga,
input                   rst_vga,
input                   vga_rd,
//input                   first_pixel, // indicate this read is the first pixel.
output [PWIDTH-1:0]     vga_pixel,
// Core side
input                   clk_core,
input                   rst_core,
input                   vram_busy,
output [AWIDTH-1:0]     vram_addr,
output                  vram_rd,
input [PWIDTH-1:0]      vram_data,
input                   vram_vld,
output                  resync_err  // need a resync happends, to help debug
);

// =====================================
// Common signal/parameter
// =====================================
localparam BUFSIZE = 1 << $clog2(`HCNT);    // buffer size
localparam WR_LATENCY = 10;                 // number of cycle takes to get a write data.
localparam RD_LATENCY = 0;                  // not really used

// =====================================
// VGA side
// =====================================
wire                buffer_empty;
//wire                resync_req_vga;
wire                fifo_rd;

assign resync_err = buffer_empty & vga_rd;
assign fifo_rd = ~buffer_empty & vga_rd;

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

assign vram_addr = {v_addr, h_addr};
assign vram_rd = ~buffer_almost_full & ~vram_busy;
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
    .AMOST_FULL(WR_LATENCY),
    .AMOST_EMPTY(RD_LATENCY)
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