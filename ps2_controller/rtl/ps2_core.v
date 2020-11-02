///////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 by Heqing Huang (feipenghhq@gamil.com)
//
// Project Name: PS2 Controller
// Module Name: ps2_core
//
// Author: Heqing Huang
// Date Created: 10/31/2020
//
// ================== Description ==================
//
// 10/31/2020 - Version 1.0: Initial version
//
//  PS2 core logic. Provides the PS2 interface between host and device.
//
//  Only have RX path right now
//
///////////////////////////////////////////////////////////////////////////////

module ps2_core
(
input               clk,
input               rst,

// PS2 interface
input               ps2_data_i,
output              ps2_data_w,
output              ps2_data_o,
input               ps2_clk_i,
output              ps2_clk_w,
output              ps2_clk_o,

// Host interface
input               hold_req,           // request to hold
output [7:0]        rcv_data,
output              rcv_parity_err,
output              rcv_vld,
/* verilator lint_off UNUSED */
input               send_req,
input [7:0]         send_data,
/* verilator lint_on UNUSED */
output              idle
);

wire        rcv_idle;

// ================================================
// Glue logic
// ================================================
assign ps2_data_w = 1'b0;
assign ps2_data_o = 1'b0;

assign idle = rcv_idle;

// ================================================
// Module Instantiation
// ================================================
ps2_rx  ps2_rx
(
    .clk            (clk),
    .rst            (rst),
    .ps2_data_i     (ps2_data_i),
    .ps2_clk_i      (ps2_clk_i),
    .ps2_clk_w      (ps2_clk_w),
    .ps2_clk_o      (ps2_clk_o),
    .hold_req       (hold_req),
    .rx_en          (1'b1),     // always enable rx path for now
    .rcv_data       (rcv_data),
    .rcv_parity_err (rcv_parity_err),
    .rcv_vld        (rcv_vld),
    .rcv_idle       (rcv_idle)
);

endmodule
