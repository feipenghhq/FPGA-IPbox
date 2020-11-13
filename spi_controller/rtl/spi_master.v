///////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 by Heqing Huang (feipenghhq@gamil.com)
//
// Project Name: spi
// Module Name: spi_master
//
// Author: Heqing Huang
// Date Created: 11/12/2020
//
// ================== Description ==================
//
// Version 1.0:
//
// A simple SPI master.
//
// 1. The spi clock frequency is fixed to half of the system clock
//    The input clock is divided into half to generate the SPI clock.
// 2. Support 4 SPI modes. Specified by cpol and cpha input.
// 3. Support only 1 endpoint for now
//
///////////////////////////////////////////////////////////////////////////////

module spi_master #(
parameter DWIDTH = 8    // data width
) (
input               clk,
input               rst,

// User data interface
input               send,
input               receive,
input [DWIDTH-1:0]  din,
input [DWIDTH-1:0]  din_nonsend,    // data to be send during read only operation
output [DWIDTH-1:0] dout,
output              rvld,

// config and status
input               cpol,   // polarity of the clock
input               cpha,   // polarity of the data
output              idle,

// SPI signal
output              sclk,   // SPI serial clock
output              mosi,   // Master Out Slave in
input               miso,   // Master in Slave out
output              cs      // Chip select
);

// ==================================================
// Parameters and signals
// ==================================================
reg                 sclk_q;
reg [DWIDTH-1:0]    send_data_q;
reg [DWIDTH-1:0]    read_data_q;
reg [$clog2(DWIDTH+1)-1:0] bit_cnt_q;

wire                data_xfer_done;
wire                sclk_1st_half;      // in dicate we are on the first half of the sclk.
wire                sclk_2nd_half;      // in dicate we are on the second half of the sclk.
wire                shift;
wire                capture;

// state machine
localparam IDLE = 3'b001;
localparam DATA = 3'b010;
localparam END  = 3'b100;
reg [2:0] spi_state;


// ==================================================
// SPI clock generation
// ==================================================
always @(posedge clk) begin
    if (rst) begin
        sclk_q <= cpol;
    end
    else begin
        if (spi_state == IDLE || spi_state == END) sclk_q <= cpol;
        else sclk_q <= ~sclk_q;
    end
end

// ==================================================
// State control
// ==================================================

always @(posedge clk) begin
    if (rst) spi_state <= IDLE;
    else begin
        case(spi_state)
            IDLE: if (send | receive) spi_state <= DATA;
            DATA: if (data_xfer_done) spi_state <= END;
            END: spi_state <= IDLE;
            default: spi_state <= IDLE;
        endcase
    end
end

assign sclk_1st_half = ~cpol & ~sclk_q | cpol & sclk_q;
assign sclk_2nd_half = ~cpol & sclk_q | cpol & ~sclk_q;

always @(posedge clk) begin
    if (rst) bit_cnt_q <= 0;
    else begin
        if ((spi_state) == DATA && sclk_2nd_half)
            bit_cnt_q <= bit_cnt_q + 1'b1;
    end
end

// last data transfer and last spi clk level.
assign data_xfer_done = (bit_cnt_q == (DWIDTH - 1'b1)) & sclk_2nd_half;
assign idle = (spi_state == IDLE);

// ==================================================
// Data Shift in And Data Shift out and other logic
// ==================================================
assign cs = (spi_state != IDLE);
assign sclk = sclk_q;
assign mosi = send_data_q[DWIDTH-1]; // MSB first
assign dout = read_data_q;
assign rvld = (spi_state == END);

// for cpha == 1, do not shift at the first bit, because the first bit is ready before the first shift
assign shift = (cpha & sclk_1st_half & |bit_cnt_q) | (~cpha & sclk_2nd_half);
assign capture = (~cpha & sclk_1st_half) | (cpha & sclk_2nd_half);

always @(posedge clk) begin
    if (rst) bit_cnt_q <= 'b0;
    else begin
        if (spi_state == IDLE) bit_cnt_q <= 'b0;
        else if (sclk_2nd_half) bit_cnt_q <= bit_cnt_q + 1'b1;
    end
end

always @(posedge clk) begin
    if (send && idle) send_data_q <= din;
    else if (receive && idle) send_data_q <= din_nonsend;
    else if (shift) send_data_q <= send_data_q << 1'b1;
end

always @(posedge clk) begin
    // no cdc here, slave device should make sure the data is ready and stable.
    if (capture) read_data_q <= {read_data_q[DWIDTH-2:0], miso};
end

endmodule