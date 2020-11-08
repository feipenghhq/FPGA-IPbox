///////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 by Heqing Huang (feipenghhq@gamil.com)
//
// Project Name: VGA
// Module Name: vga_sync
//
// Author: Heqing Huang
// Date Created: 11/05/2020
//
// ================== Description ==================
//
//  Initial version created at 05/09/2019.
//  A new version based on the initial version created at 11/05/2020
//
//  This module implements the vga sync pulse logic (vsync, hsync).
//  The input clk_vga period is the clock required by the resolution.
//
///////////////////////////////////////////////////////////////////////////////


`define ADV7123
`include "vga.vh"

module vga_sync #(
parameter HADDRW = $clog2(`HVA),      // horizontal address width
parameter VADDRW = $clog2(`VVA)       // vertical address width
)(
input                       clk_vga,
input                       rst_vga,

`ifdef ADV7123
// used only for the ADV7123 chip on DE2 board
output reg                  adv7123_vga_blank,
output                      adv7123_vga_sync,
output                      adv7123_vga_clk,
`endif

// VGA output
output                      vga_hsync,
output                      vga_vsync,
output                      vga_video_on,
output                      first_pixel
);

// state machine sequence: SP => BP => VA => FP
localparam VA = 4'b0001;            // visible area
localparam FP = 4'b0010;            // front porch
localparam SP = 4'b0100;            // sync pulse
localparam BP = 4'b1000;            // back porch

localparam HCNT = `HVA + `HFP + `HSP + `HBP;
localparam VCNT = `VVA + `VFP + `VSP + `VBP;

reg [3:0]                   v_state_q;
reg [3:0]                   h_state_q;
reg                         hsync_q;
reg                         vsync_q;
reg                         video_on_q;
reg                         first_pixel_q;
reg [$clog2(HCNT+1)-1:0]    h_count_q;
reg [$clog2(VCNT+1)-1:0]    v_count_q;

wire horizontal_on;  // horizontal video on
wire vertical_on;    // vertical video on
wire h_tick;         // horizontal scan completes

//==========================================
// horizontal state machine
//==========================================

always @(posedge clk_vga) begin
    if (rst_vga) begin
        h_state_q <= SP;
    end
    else begin
        /* verilator lint_off CASEINCOMPLETE */
        case(h_state_q)
        /* verilator lint_on CASEINCOMPLETE */
            SP: if (h_count_q == `HSP-1) h_state_q <= BP;
            BP: if (h_count_q == `HBP-1) h_state_q <= VA;
            VA: if (h_count_q == `HVA-1) h_state_q <= FP;
            FP: if (h_count_q == `HFP-1) h_state_q <= SP;
        endcase
    end
end

//==========================================
// horizontal OFL
//==========================================

always @(posedge clk_vga) begin
    if (rst_vga) begin
        h_count_q <= 'b0;
    end
    else begin
        h_count_q <= h_count_q + 1'd1;  // default adding 1 to h count
        /* verilator lint_off CASEINCOMPLETE */
        case(h_state_q)
        /* verilator lint_on CASEINCOMPLETE */
        SP: if (h_count_q == `HSP-1) h_count_q <= 'b0;
        BP: if (h_count_q == `HBP-1) h_count_q <= 'b0;
        VA: begin
            if (h_count_q == `HVA-1) h_count_q <= 'b0;
        end
        FP: if (h_count_q == `HFP-1) h_count_q <= 'b0;
        endcase
    end
end

assign h_tick = (h_state_q == FP && h_count_q == `HFP-1);

//======================================
// vertical state machine
//======================================
always @(posedge clk_vga) begin
    if (rst_vga) begin
        v_state_q <= SP;
    end
    else if (h_tick) begin
        /* verilator lint_off CASEINCOMPLETE */
        case(v_state_q)
        /* verilator lint_on CASEINCOMPLETE */
            SP: if (v_count_q == `VSP-1) v_state_q <= BP;
            BP: if (v_count_q == `VBP-1) v_state_q <= VA;
            VA: if (v_count_q == `VVA-1) v_state_q <= FP;
            FP: if (v_count_q == `VFP-1) v_state_q <= SP;
        endcase
    end
end

//======================================
// vertical OFL
//======================================
always @(posedge clk_vga) begin
    if (rst_vga) begin
        v_count_q <= 'b0;
    end
    else if (h_tick) begin
        v_count_q <= v_count_q + 1'd1;
        /* verilator lint_off CASEINCOMPLETE */
        case(v_state_q)
        /* verilator lint_on CASEINCOMPLETE */
        SP: if (v_count_q == `VSP-1) v_count_q <= 'b0;
        BP: if (v_count_q == `VBP-1) v_count_q <= 'b0;
        VA: if (v_count_q == `VVA-1) v_count_q <= 'b0;
        FP: if (v_count_q == `VFP-1) v_count_q <= 'b0;
        endcase
    end
end

//=====================
// output logic
//=====================

assign horizontal_on    = (h_state_q == VA) ? 1'b1 : 1'b0;
assign vertical_on      = (v_state_q == VA) ? 1'b1 : 1'b0;

always @(posedge clk_vga) begin
    if (rst_vga) begin
        hsync_q <= 1'b0;
        vsync_q <= 1'b0;
        video_on_q <= 1'b0;
        first_pixel_q <= 1'b0;
    end
    else begin
        video_on_q <= horizontal_on & vertical_on;
        hsync_q <= (h_state_q == SP) ? 1'b0 : 1'b1;
        vsync_q <= (v_state_q == SP) ? 1'b0 : 1'b1;
        first_pixel_q <= ((h_count_q == 0) & horizontal_on) & ((v_count_q == 0) & vertical_on);
    end
end

assign vga_hsync = hsync_q;
assign vga_vsync = vsync_q;
assign vga_video_on = video_on_q;
assign first_pixel = first_pixel_q;

`ifdef ADV7123
    assign adv7123_vga_sync = 1'b0;
    assign adv7123_vga_clk = clk_vga;

    always @(posedge clk_vga) begin
        if (rst_vga) adv7123_vga_blank <= 1'b1;
        else adv7123_vga_blank <= hsync_q & vsync_q;
    end
`endif

endmodule
