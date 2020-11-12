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
// Instantiate the vga_sync and vga_vram_buffer
// Decode the pixel data into R/G/B channel.
//
///////////////////////////////////////////////////////////////////////////////

`define ADV7123

module vga_controller #(
parameter BUFSIZE = 128,    // Pixel buffer FIFO size.
parameter PWIDTH  = 8,      // Pixel width
parameter AWIDTH  = 19,     // vram address size. Should be $clog2(`VCNT) + $clog2(`HCNT)
parameter LATENCY = 2,      // vram read latency
parameter RWIDTH  = 10,     // R color width
parameter GWIDTH  = 10,     // G color width
parameter BWIDTH  = 10,     // B color width
parameter COLORTYPE  = 0   // color type. 0: 8 bit color
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
output                  out_sync
);

wire [PWIDTH-1:0]       vga_pixel;
wire                    first_pixel;


generate
if (COLORTYPE == 0) begin // use 8 bit pixel
    assign vga_r = {vga_pixel[7:5], {(RWIDTH - 3){1'b0}}};
    assign vga_g = {vga_pixel[4:2], {(GWIDTH - 3){1'b0}}};
    assign vga_b = {vga_pixel[1:0], {(BWIDTH - 2){1'b0}}};
end
else begin// output white screen
    assign vga_r = {RWIDTH{1'b1}};
    assign vga_g = {GWIDTH{1'b1}};
    assign vga_b = {BWIDTH{1'b1}};
end
endgenerate


vga_vram_buffer #(
    .BUFSIZE(BUFSIZE),
    .PWIDTH(PWIDTH),
    .LATENCY(LATENCY)
) vga_vram_buffer (
    .clk_vga    (clk_vga),
    .rst_vga    (rst_vga),
    .vga_rd     (vga_video_on),
    .first_pixel(first_pixel),
    .vga_pixel  (vga_pixel),
    .clk_core   (clk_core),
    .rst_core   (rst_core),
    .vram_busy  (vram_busy),
    .vram_addr  (vram_addr),
    .vram_rd    (vram_rd),
    .vram_data  (vram_data),
    .vram_vld   (vram_vld),
    .out_sync   (out_sync)
);

vga_sync vga_sync (
    .clk_vga            (clk_vga),
    .rst_vga            (rst_vga),
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