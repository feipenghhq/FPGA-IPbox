///////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 by Heqing Huang (feipenghhq@gamil.com)
//
// Project Name: VGA
// Module Name: vga_controller_tb
//
// Author: Heqing Huang
// Date Created: 11/08/2019
//
// ================== Description ==================
//
// Testbench for vga_controller. No thing very interesting here.
// The design is verified mainly by looking at the waveform and FPGA testing
//
///////////////////////////////////////////////////////////////////////////////

`define ADV7123
`define _VGA_640_480    // define the macro first before importing the file
`include "vga.vh"

module vga_controller_tb ();

parameter PWIDTH  = 8;
parameter AWIDTH  = 19;
parameter LATENCY = 4;
parameter RWIDTH  = 10;
parameter GWIDTH  = 10;
parameter BWIDTH  = 10;

parameter CLK_VGA = 20;
parameter CLK_CORE = 10;

reg                   clk_vga;
reg                   rst_vga = 1;
reg                   clk_core;
reg                   rst_core = 1;

wire                  vga_hsync;
wire                  vga_vsync;
wire                  vga_video_on;
wire [RWIDTH-1:0]     vga_r;
wire [GWIDTH-1:0]     vga_g;
wire [BWIDTH-1:0]     vga_b;

reg                   vram_busy = 0;
wire [AWIDTH-1:0]     vram_addr;
wire                  vram_rd;
reg [PWIDTH-1:0]      vram_data;
reg                   vram_vld = 0;
wire                  resync_err;

`ifdef ADV7123
wire                  adv7123_vga_blank;
wire                  adv7123_vga_sync;
wire                  adv7123_vga_clk;
`endif


vga_controller dut_vga_controller (.*);

initial
begin
    wait(rst_vga == 0 && rst_core == 0);
    #10000000;
    $finish;
end


always @(*) begin
    vram_data = vram_addr;
    vram_vld = vram_rd;
end

// ================================================
// clock and reset
// ================================================
initial
begin
    clk_vga = 1;
    forever begin
        #(CLK_VGA/2) clk_vga = ~clk_vga;
    end
end

initial
begin
    clk_core = 1;
    forever begin
        #(CLK_CORE/2) clk_core = ~clk_core;
    end
end

initial
begin
    rst_vga = 1'b1;
    #100;
    @(posedge clk_vga);
    #1 rst_vga = 1'b0;
end


initial
begin
    rst_core = 1'b1;
    #100;
    @(posedge clk_core);
    #1 rst_core = 1'b0;
end

// ================================================
// Dump test
// ================================================
initial
begin
    $dumpfile("dump.vcd");
    $dumpvars(0, vga_controller_tb);
end

endmodule