///////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 by Heqing Huang (feipenghhq@gamil.com)
//
// Project Name: VGA
// Module Name: vga_controller_tb
//
// Author: Heqing Huang
// Date Created: 05/09/2019
//
// ================== Description ==================
//
// Testbench for vga_sync. No thing very interesting here.
// The design is verified mainly by looking at the waveform and FPGA testing
//
///////////////////////////////////////////////////////////////////////////////

`define ADV7123
`define _VGA_640_480    // define the macro first before importing the file
`include "vga.vh"

module vga_sync_tb ();
parameter HADDRW = $clog2(`HVA);
parameter VADDRW = $clog2(`VVA);
parameter CLK_PROD = 10;
reg                       vga_clk;
reg                       rst = 1;
`ifdef ADV7123
// used only for the ADV7123 chip on DE2 board
wire                      adv7123_vga_blank;
wire                      adv7123_vga_sync;
wire                      adv7123_vga_clk;
`endif
// VGA wire
wire                      vga_hsync;
wire                      vga_vsync;
wire                      vga_video_on;
wire     [HADDRW-1:0]     vga_h_addr;
wire     [VADDRW-1:0]     vga_v_addr;

vga_sync dut_vga_sync(.*);

initial
begin
    rst = 1'b1;
    #100;
    @(posedge vga_clk);
    #1 rst = 1'b0;
    #10000000;
    $finish;
end


// ================================================
// clock
// ================================================
initial
begin
    vga_clk = 1;
    forever begin
        #(CLK_PROD/2) vga_clk = ~vga_clk;
    end
end

// ================================================
// Dump test
// ================================================
initial
begin
    $dumpfile("dump.vcd");
    $dumpvars(0, vga_sync_tb);
end

endmodule