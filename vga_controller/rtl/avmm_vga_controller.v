///////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 by Heqing Huang (feipenghhq@gamil.com)
//
// Project Name: VGA
// Module Name: avmm_vga_controller
//
// Author: Heqing Huang
// Date Created: 11/08/2020
//
// ================== Description ==================
//
// Avalon Memory Mapped VGA controller.
//
///////////////////////////////////////////////////////////////////////////////

`define ADV7123

module avmm_vga_controller #(
parameter BUFSIZE = 128,   // Pixel buffer FIFO size.
parameter PWIDTH  = 8,     // Pixel width
parameter AWIDTH  = 19,    // vram address size. Should be $clog2(`VCNT) + $clog2(`HCNT)
parameter LATENCY = 4,     // vram read latency
parameter RWIDTH  = 10,    // R color width
parameter GWIDTH  = 10,    // G color width
parameter BWIDTH  = 10,    // B color width
parameter COLORTYPE  = 0   // color type. 0: 8 bit color
) (
input                   clk_vga,
input                   rst_vga,
input                   clk_core,
input                   rst_core,
// used only for the ADV7123 chip on DE2 board
`ifdef ADV7123
output                  adv7123_vga_blank,
output                  adv7123_vga_sync,
output                  adv7123_vga_clk,
`endif
// VGA signal
output                  vga_hsync,
output                  vga_vsync,
output                  vga_video_on,
output [RWIDTH-1:0]     vga_r,
output [GWIDTH-1:0]     vga_g,
output [BWIDTH-1:0]     vga_b,
output                  out_sync,
// Avalon Memory Mapped Master for access VRAM
input                   avm_waitrequest,
input [PWIDTH-1:0]      avm_readdata,
input                   avm_readdatavalid,
output [AWIDTH-1:0]     avm_address,
output                  avm_read
);

vga_controller #(
    .BUFSIZE(BUFSIZE),
    .PWIDTH(PWIDTH),
    .AWIDTH(AWIDTH),
    .LATENCY(LATENCY),
    .RWIDTH(RWIDTH),
    .GWIDTH(GWIDTH),
    .BWIDTH(BWIDTH),
    .COLORTYPE(COLORTYPE)
) vga_controller (
    .clk_vga            (clk_vga),
    .rst_vga            (rst_vga),
    .clk_core           (clk_core),
    .rst_core           (rst_core),
    `ifdef ADV7123
    .adv7123_vga_blank  (adv7123_vga_blank),
    .adv7123_vga_sync   (adv7123_vga_sync),
    .adv7123_vga_clk    (adv7123_vga_clk),
    `endif
    .vga_hsync          (vga_hsync),
    .vga_vsync          (vga_vsync),
    .vga_video_on       (vga_video_on),
    .vga_r              (vga_r),
    .vga_g              (vga_g),
    .vga_b              (vga_b),
    .vram_busy          (avm_waitrequest),
    .vram_addr          (avm_address),
    .vram_rd            (avm_read),
    .vram_data          (avm_readdata),
    .vram_vld           (avm_readdatavalid),
    .out_sync           (out_sync)
);

endmodule