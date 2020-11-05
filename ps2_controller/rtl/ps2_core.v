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

module ps2_core #(
parameter CLK = 50  // Clock period in MHz
)(
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
input               send_req,
input [7:0]         send_data,
output              idle
);

wire        rcv_idle;
wire        send_idle;
wire        rx_en;
wire        rx_busy;

wire        rx_ps2_clk_w;
wire        rx_ps2_clk_o;
wire        tx_ps2_data_w;
wire        tx_ps2_data_o;
wire        tx_ps2_clk_w;
wire        tx_ps2_clk_o;

// ================================================
// Glue logic
// ================================================

assign idle = rcv_idle & send_idle;
assign rx_busy = ~rcv_idle;
assign rx_en = send_idle;

assign ps2_clk_w = rx_ps2_clk_w | tx_ps2_clk_w;
assign ps2_clk_o = (rx_ps2_clk_w & rx_ps2_clk_o) | (tx_ps2_clk_w & tx_ps2_clk_o);
assign ps2_data_w = tx_ps2_data_w;
assign ps2_data_o = tx_ps2_data_o;

// ================================================
// Module Instantiation
// ================================================
ps2_rx  ps2_rx
(
    .clk            (clk),
    .rst            (rst),
    .ps2_data_i     (ps2_data_i),
    .ps2_clk_i      (ps2_clk_i),
    .ps2_clk_w      (rx_ps2_clk_w),
    .ps2_clk_o      (rx_ps2_clk_o),
    .hold_req       (hold_req),
    .rx_en          (rx_en),
    .rcv_data       (rcv_data),
    .rcv_parity_err (rcv_parity_err),
    .rcv_vld        (rcv_vld),
    .rcv_idle       (rcv_idle)
);

ps2_tx #(.CLK(CLK))  ps2_tx 
(
    .clk            (clk),
    .rst            (rst),
    .ps2_data_i     (ps2_data_i),
    .ps2_data_o     (tx_ps2_data_o),
    .ps2_data_w     (tx_ps2_data_w),
    .ps2_clk_i      (ps2_clk_i),
    .ps2_clk_w      (tx_ps2_clk_w),
    .ps2_clk_o      (tx_ps2_clk_o),
    .rx_busy        (rx_busy),
    .send_req       (send_req),
    .send_data      (send_data),
    .send_idle      (send_idle)
);

endmodule
