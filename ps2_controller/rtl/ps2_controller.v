///////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 by Heqing Huang (feipenghhq@gamil.com)
//
// Project Name: PS2 Controller
// Module Name: ps2_controller
//
// Author: Heqing Huang
// Date Created: 10/31/2020
//
// ================== Description ==================
//
// PS2 Controller
//
///////////////////////////////////////////////////////////////////////////////

module ps2_controller #(
parameter SYSCLK = 50       // System clock rate in MHz
parameter RX_FIFO_SIZE = 16,
parameter TX_FIFO_SIZE = 4
) (

// clock and reset
input           clk,
input           rst,

// register access interface
input  [2:0]    sw_address,
input           sw_read,
input           sw_write,
input           sw_select,
input  [31:0]   sw_wrdata,
output [31:0]   sw_rddata,

// PS2 interface
input           ps2_data_i,
output          ps2_data_w,
output          ps2_data_o,
input           ps2_clk_i,
output          ps2_clk_w,
output          ps2_clk_o,

// interrupt port
output          ps2_data_avail
);

wire        hold_req;
wire [7:0]  rcv_data;
wire        rcv_parity_err;
wire        rcv_vld;
wire        send_req;
wire [7:0]  send_data;
wire        ps2_idle;

wire        tx_fifo_write;
wire        tx_fifo_read;
wire [7:0]  tx_fifo_write_data;
wire        tx_fifo_full;
wire        tx_fifo_empty;

wire        rx_fifo_read;
wire        rx_fifo_write;
wire [7:0]  rx_fifo_read_data;
wire        rx_fifo_empty;
wire        rx_fifo_full;

// ================================================
// Glue logic
// ================================================
assign  hold_req = rx_fifo_full;
assign  rx_fifo_write = rcv_vld & ~rcv_parity_err & ~rx_fifo_full;
assign  send_req = ~tx_fifo_empty & ps2_idle;
assign  tx_fifo_read = send_req;
assign  ps2_data_avail = ~rx_fifo_empty;

// ================================================
// Module Instantiation
// ================================================

// CSR module
ps2_csr ps2_csr
(
    .clk                                  (clk),
    .reset                                (rst),
    .i_sw_address                         (sw_address),
    .i_sw_read                            (sw_read),
    .i_sw_write                           (sw_write),
    .i_sw_select                          (sw_select),
    .i_sw_wrdata                          (sw_wrdata),
    .o_sw_rddata                          (sw_rddata),
    .o_hw_data_tx_fifo_fifo_write         (tx_fifo_write),
    .o_hw_data_tx_fifo_fifo_write_data    (tx_fifo_write_data),
    .o_hw_data_rx_fifo_fifo_read          (rx_fifo_read),
    .i_hw_data_rx_fifo_fifo_read_data     (rx_fifo_read_data),
    .i_hw_status_tx_fifo_full             (tx_fifo_full),
    .i_hw_status_rx_fifo_empty            (rx_fifo_empty)
);

// RX FIFO
fwft_fifo #(.DWIDTH(8), .DEPTH(RX_FIFO_SIZE)) ps2_rx_fifo
(
    .rst    (rst),
    .clk    (clk),
    .write  (rx_fifo_write),
    .read   (rx_fifo_read),
    .din    (rcv_data),
    .dout   (rx_fifo_read_data),
    .full   (rx_fifo_full),
    .empty  (rx_fifo_empty)
);

// TX FIFO
fwft_fifo #(.DWIDTH(8), .DEPTH(TX_FIFO_SIZE)) ps2_tx_fifo
(
    .rst    (rst),
    .clk    (clk),
    .write  (tx_fifo_write),
    .read   (tx_fifo_read),
    .din    (tx_fifo_write_data),
    .dout   (send_data),
    .full   (tx_fifo_full),
    .empty  (tx_fifo_empty)
);

// PS2 Core
ps2_core ps2_core
(
    .clk             (clk),
    .rst             (rst),
    .ps2_data_i      (ps2_data_i),
    .ps2_data_w      (ps2_data_w),
    .ps2_data_o      (ps2_data_o),
    .ps2_clk_i       (ps2_clk_i),
    .ps2_clk_w       (ps2_clk_w),
    .ps2_clk_o       (ps2_clk_o),
    .hold_req        (hold_req),
    .rcv_data        (rcv_data),
    .rcv_parity_err  (rcv_parity_err),
    .rcv_vld         (rcv_vld),
    .send_req        (send_req),
    .send_data       (send_data),
    .idle            (ps2_idle)
);

endmodule
