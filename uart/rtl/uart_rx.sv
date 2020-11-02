///////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 by Heqing Huang (feipenghhq@gamil.com)
//
// Project Name: Uart
// Module Name: uart_rx
//
// Author: Heqing Huang
// Date Created: 05/06/2019
//
// ================== Description ==================
//
//  Revision 1.0:
//   Uart receiver logic.
//   1. buadrate and clock frequency are controlled by parameters.
//   2. This design support fixed 8 bit.
//   3. configurable parity: Support no parity, even parity, odd parity
//      cfg_parity bit 0: 0 no parity, 1 has parity.
//      cfg_parity bit 1: 0 even parity, 1 odd parity
//   4. configurable number of stop bit. Support 1, 1.5, 2 bits
//      cfg_stop_bits: 0 - 1 bit; 1 - 1.5 bit; 2 - 2 bit
//
///////////////////////////////////////////////////////////////////////////////

module uart_rx #(
parameter BUADRATE = 115200,      // buadrate
parameter CLKFRQ   = 100          // clock frequence in Mhz
) (
input        clk,
input        rst,
input [1:0]  cfg_parity,         // See description
input [1:0]  cfg_stop_bits,      // See description
input        uart_rx,
output [7:0] rxdout,
output reg   rxvalid,
output reg   parity_err
);

//==============================
// Signal Declaration
//==============================

localparam SAMPLE_RATE = 16;
localparam SAMPLE_COUNT = CLKFRQ * 1000000 / (BUADRATE * SAMPLE_RATE);

reg             sample;
reg [15:0]      buad_count;

// state machine
typedef enum logic [4:0] {
    IDLE   = 5'b00001,
    START  = 5'b00010,
    DATA   = 5'b00100,
    PARITY = 5'b01000,
    STOP   = 5'b10000
} rx_state_t;

rx_state_t rx_state;

reg [7:0]       data;
reg [4:0]       data_cnt;
reg [5:0]       sample_cnt;
reg             parity;
reg [5:0]       stop_cnt_static;

logic           sampled_all;         // sampled enough pulse (SAMPLE_RATE)
logic           rx_sync;
logic           rst_buad;

//=================================
// Buad sample generation
//=================================
// Generate sample pulse to sample uart data based on buad rate.
// The most commonly used sample rate is 16 times the buad rate,
// which means that each serial bit is sampled 16 times.

always_ff @(posedge clk) begin
    if (rst_buad) begin         // no global reset needed here.
        sample <= 1'b0;
        buad_count  <= 'b0;
    end
    else begin
        if (buad_count == SAMPLE_COUNT) begin
            sample <= 1'b1;
            buad_count  <= 'b0;
        end
        else begin
            sample <= 1'b0;
            buad_count  <= buad_count + 1;
        end
    end
end

//=================================
// Uart TX logic
//=================================
// Phase: Start, DATA, PARITY, STOP.
// We should sample in the middle of each serial bit.
// In order to sample in te middle, we first sample half of the sample which
// give us the middle of the start bit. Then we sample all the sample pulse
// which will be the middle of the next serial bit.

// synchronize the input bit
dsync uart_rx_dsync (.Q(rx_sync), .D(uart_rx), .clk(clk), .rst(rst));

assign sampled_all = (sample_cnt == SAMPLE_RATE);
assign rst_buad = (rx_state == IDLE);
assign rxdout = data;

// state machine
always_ff @(posedge clk) begin
    if(rst) begin
        rx_state    <= IDLE;
    end
    else begin
        case(rx_state)
        IDLE: begin
            if (!rx_sync)
                rx_state <= START;
        end
        START: begin
            if (rx_sync)
                rx_state <= IDLE;
            else if (sample_cnt == SAMPLE_RATE / 2)
                rx_state <= DATA;
        end
        DATA: begin
            if (data_cnt == 8)
                rx_state <= (cfg_parity[0]) ? PARITY : STOP;
        end
        PARITY: begin
            if (sampled_all)
                rx_state <= STOP;
        end
        STOP: begin
            if (sample_cnt == stop_cnt_static)
                rx_state <= IDLE;
        end
        endcase
    end
end

always_ff @(posedge clk) begin
    if(rst) begin
        data_cnt    <= 'b0;
        data        <= 'b0;
        rxvalid     <= 'b0;
        sample_cnt  <= 'b0;
        parity      <= 'b0;
        parity_err  <= 'b0;
        stop_cnt_static <= 'b0;
    end
    else begin
        stop_cnt_static <= (cfg_stop_bits == 2'b00) ? 16 : (cfg_stop_bits == 2'b01) ? 24 : 32;

        case(rx_state)
        IDLE: begin
            sample_cnt  <= 'b0;
            data_cnt    <= 'b0;
            parity      <= 'b0;
        end
        START: begin
            sample_cnt  <= (sample_cnt == SAMPLE_RATE / 2) ? 'b0 : (sample ? sample_cnt + 1 : sample_cnt);
        end
        DATA: begin
            sample_cnt  <= sampled_all ? 'b0 : (sample ? sample_cnt + 1 : sample_cnt);
            data_cnt    <= sampled_all ? data_cnt + 1 : data_cnt;
            data        <= sampled_all ? {rx_sync, data[7:1]} : data;
            parity      <= sampled_all ? parity ^ rx_sync : parity;
            rxvalid     <= (data_cnt == 8) ? (~cfg_parity[0]) : 'b0;        // if no parity check, set the rxvalid here.
        end
        PARITY: begin
            sample_cnt  <= sampled_all ? 'b0 : (sample ? sample_cnt + 1 : sample_cnt);
            parity_err  <= sampled_all ? parity ^ rx_sync ^ cfg_parity[1] : 1'b0;
            rxvalid     <= sampled_all ? 1'b1 : 1'b0;
        end
        STOP: begin
            rxvalid     <= 1'b0;
            sample_cnt  <= sample ? sample_cnt + 1 : sample_cnt;
        end
        endcase
    end
end

endmodule