///////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 by Heqing Huang (feipenghhq@gamil.com)
//
// Project Name: VGA
// Module Name: vga_controller
//
// Author: Heqing Huang
// Date Created: 11/07/2020
//
// ================== Description ==================
//
// VGA controller top level.
// Instantiate the vga_sync and vga_vram_ctrl
// Decode the pixel data into R/G/B channel.
//
///////////////////////////////////////////////////////////////////////////////

`define ADV7123
`define _8BIT // use 8 bit pixel

module vga_controller #(
parameter PWIDTH  = 8,      // pixel width
parameter AWIDTH  = 19,     // should be $clog2(`VCNT) + $clog2(`HCNT)
parameter LATENCY = 4,      // vram read latency
parameter RWIDTH  = 10,
parameter GWIDTH  = 10,
parameter BWIDTH  = 10
) (
input                   clk_vga,
input                   rst_vga,
input                   clk_core,
input                   rst_core,

`ifdef ADV7123
// used only for the ADV7123 chip on DE2 board
output                  adv7123_vga_blank,
output                  adv7123_vga_sync,
output                  adv7123_vga_clk,
`endif

output                  vga_hsync,
output                  vga_vsync,
output                  vga_video_on,
output [RWIDTH-1:0]     vga_r,
output [GWIDTH-1:0]     vga_g,
output [BWIDTH-1:0]     vga_b,

input                   vram_busy,
output [AWIDTH-1:0]     vram_addr,
output                  vram_rd,
input [PWIDTH-1:0]      vram_data,
input                   vram_vld,
output                  resync_err
);

wire [PWIDTH-1:0]       vga_pixel;
/* verilator lint_off UNUSED */
wire                    first_pixel;
/* verilator lint_on UNUSED */


`ifdef _8BIT // use 8 bit pixel
    assign vga_r = {vga_pixel[7:5], {(RWIDTH - 3){1'b0}}};
    assign vga_g = {vga_pixel[4:2], {(GWIDTH - 3){1'b0}}};
    assign vga_b = {vga_pixel[1:0], {(BWIDTH - 2){1'b0}}};
`else // output white screen
    assign vga_r = {RWIDTH{1'b1}};
    assign vga_g = {GWIDTH{1'b1}};
    assign vga_b = {BWIDTH{1'b1}};
`endif


vga_vram_ctrl #(
    .PWIDTH(PWIDTH),
    .LATENCY(LATENCY)
) vga_vram_ctrl (
    .clk_vga    (clk_vga),
    .rst_vga    (rst_vga),
    .vga_rd     (vga_video_on),
    .vga_pixel  (vga_pixel),
    .clk_core   (clk_core),
    .rst_core   (rst_core),
    .vram_busy  (vram_busy),
    .vram_addr  (vram_addr),
    .vram_rd    (vram_rd),
    .vram_data  (vram_data),
    .vram_vld   (vram_vld),
    .resync_err (resync_err)
);

vga_sync vga_sync (
    .clk_vga            (clk_vga),
    .rst                (rst_vga),
    `ifdef ADV7123
    .adv7123_vga_blank  (adv7123_vga_blank),
    .adv7123_vga_sync   (adv7123_vga_sync),
    .adv7123_vga_clk    (adv7123_vga_clk),
    `endif
    .vga_hsync          (vga_hsync),
    .vga_vsync          (vga_vsync),
    .vga_video_on       (vga_video_on),
    .first_pixel        (first_pixel)
);

endmodule