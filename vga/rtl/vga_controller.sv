///////////////////////////////////////////////////////////////////////////////
//
// Project Name: VGA
// Module Name: vga_controller
//
// Author: Heqing Huang
// Date Created: 05/09/2019
//
// ================== Description ==================
//
//  This module implements the vga controller logic.
//
//  The input clk period is the clock required by the resolution. 
//  All signal in this module are synchronized to the clock.
//
//  The access to the frame buffer (video buffer) are pipelined.
//  CLK1: vga controller output address (vga_vga_h_addr, vga_vga_v_addr) to frame buffer.
//  CLK2: frame buffer output pixel data (R,G,B) back to frame buffer.
//  CLK3: vga controller output RGB data together with hsync and vsync data.
//
///////////////////////////////////////////////////////////////////////////////


`define ALTERA_DE2
`define _VGA_640_480    // define the macro first before importing the file
`include "vga.svh"

module vga_controller #(
parameter HADDRW = 10,      // horizontal address width
parameter VADDRW = 10,      // vertical address width
parameter COLORW = 10       // color width.
)(
input                       clk,
input                       reset,

// Frame Buffer input
input [COLORW-1:0]          red,
input [COLORW-1:0]          green,
input [COLORW-1:0]          blue,

`ifdef ALTERA_DE2
// used only for the ADV7123 chip on DE2 board
output reg                  vga_blank,
output                      vga_sync,
output                      vga_clk,
`endif

// VGA output
output reg                  vga_hsync,
output reg                  vga_vsync,
output reg                  vga_video_on,
output reg [HADDRW-1:0]     vga_h_addr,
output reg [VADDRW-1:0]     vga_v_addr,
output reg                  vga_rd,
output reg [COLORW-1:0]     vga_r,
output reg [COLORW-1:0]     vga_g,
output reg [COLORW-1:0]     vga_b
);


localparam VA = 4'b0001;            // visible area
localparam FP = 4'b0010;            // front porch
localparam SP = 4'b0100;            // sync pulse
localparam BP = 4'b1000;            // back porch


reg [3:0]   v_state, h_state;       // state machine sequence: SP => BP => VA => FP
reg [9:0]   h_count, v_count;
reg         hsync_ff, vsync_ff, video_on_ff;    // CLK2 stage pipeline
logic       horizontal_on;                      // horizontal video on
logic       vertical_on;                        // vertical video on
logic       h_tick;                             // horizontal scan has completed

//==========================================
// horizontal control and state machine
//==========================================

always @(posedge clk) begin
    if (reset) begin
        h_state <= SP;
        h_count <= 'b0;
        vga_h_addr  <= 'b0;
        vga_rd  <= 'b0;
    end
    else begin
        case(h_state)
        SP: begin
            if (h_count == `HSP-1) begin
                h_state <= BP;
                h_count <= 'b0;
            end
            else h_count <= h_count + 1'd1;
        end
        BP: begin
            if (h_count == `HBP-1) begin
                h_state <= VA;
                h_count <= 'b0;
                vga_rd <= (v_state == VA);
            end
            else h_count <= h_count + 1'd1;
        end
        VA: begin
            if (h_count == `HVA-1) begin
                h_state <= FP;
                h_count <= 'b0;
                vga_h_addr  <= 'b0;
                vga_rd  <= 'b0;
            end
            else begin
                 h_count <= h_count + 1'd1;
                 vga_h_addr  <= vga_h_addr + 1'd1;
            end
        end
        FP: begin
            if (h_count == `HFP-1) begin
                h_state <= SP;
                h_count <= 'b0;
            end
            else h_count <= h_count + 1'd1;
        end
        endcase
    end
end

assign h_tick = (h_state == FP && h_count == `HFP-1);

//======================================
// vertical control and state machine
//======================================
always @(posedge clk) begin
    if (reset) begin
        v_state <= SP;
        v_count <= 'b0;
        vga_v_addr  <= 'b0;
    end
    else if (h_tick) begin
        case(v_state)
        SP: begin
            if (v_count == `VSP-1) begin
                v_state <= BP;
                v_count <= 'b0;
            end
            else v_count <= v_count + 1'd1;
        end
        BP: begin
            if (v_count == `VBP-1) begin
                v_state <= VA;
                v_count <= 'b0;
            end
            else v_count <= v_count + 1'd1;
        end
        VA: begin
            if (v_count == `VVA-1) begin
                v_state <= FP;
                v_count <= 'b0;
                vga_v_addr  <= 'b0;
            end
            else begin
                v_count <= v_count + 1'd1;
                vga_v_addr  <= vga_v_addr + 1'd1;
            end
        end
        FP: begin
            if (v_count == `VFP-1) begin
                v_state <= SP;
                v_count <= 'b0;
            end
            else v_count <= v_count + 1'd1;
        end
        endcase
    end
end

//=====================
// Other logic
//=====================

assign horizontal_on    = (h_state == VA) ? 1'b1 : 1'b0;
assign vertical_on      = (v_state == VA) ? 1'b1 : 1'b0;

always_ff @(posedge clk) begin
    if (reset) begin
        hsync_ff <= 1'b0;
        vsync_ff <= 1'b0;
        video_on_ff <= 1'b0;
    end
    else begin
        video_on_ff <= horizontal_on & vertical_on;
        hsync_ff <= (h_state == SP) ? 1'b0 : 1'b1;
        vsync_ff <= (v_state == SP) ? 1'b0 : 1'b1;
    end
end

always_ff @(posedge clk) begin
    if (reset) begin
        vga_hsync <= 1'b0;
        vga_vsync <= 1'b0;
        vga_video_on <= 1'b0;
        vga_r <= 'b0;
        vga_g <= 'b0;
        vga_b <= 'b0;
    end
    else begin
        vga_hsync <= hsync_ff;
        vga_vsync <= vsync_ff;
        vga_video_on <= video_on_ff;
        vga_r <= video_on_ff ? red   : 'b0;
        vga_g <= video_on_ff ? green : 'b0;
        vga_b <= video_on_ff ? blue  : 'b0;
    end
end

`ifdef ALTERA_DE2
assign vga_sync = 1'b0;
assign vga_clk = clk;
always_ff @(posedge clk) begin
    if (reset) vga_blank <= 1'b1;
    else vga_blank <= hsync_ff & vsync_ff;
end
`endif
endmodule
