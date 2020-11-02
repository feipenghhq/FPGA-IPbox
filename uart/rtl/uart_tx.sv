///////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 by Heqing Huang (feipenghhq@gamil.com)
//
// Project Name: Uart
// Module Name: uart_tx
//
// Author: Heqing Huang
// Date Created: 05/06/2019
//
// ================== Description ==================
//
//  Revision 1.0:
//   Uart transmitter logic.
//   1. buadrate and clock frequency are controlled by parameters.
//   2. This design support fixed 8 bit.
//   3. configurable parity: Support no parity, even parity, odd parity
//      cfg_parity bit 0: 0 no parity, 1 has parity.
//      cfg_parity bit 1: 0 even parity, 1 odd parity
//   4. configurable number of stop bit. Support 1, 1.5, 2 bits
//      cfg_stop_bits: 0 - 1 bit; 1 - 1.5 bit; 2 - 2 bit
//
///////////////////////////////////////////////////////////////////////////////

module uart_tx_core #(
parameter BUADRATE = 115200,      // buadrate
parameter CLKFRQ   = 100          // clock frequence in Mhz
) (
input       clk,
input       rst,
input [1:0] cfg_parity,         // See description
input [1:0] cfg_stop_bits,      // See description
input [7:0] txdin,
input       txvalid,
output reg  ready,
output reg  uart_tx
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
} tx_state_t;

tx_state_t tx_state;

reg [7:0]       data;
reg [3:0]       data_cnt;
reg [5:0]       sample_cnt;
reg             parity;
reg [5:0]       stop_cnt_static;

logic           sampled_all;         // sampled enough pulse (SAMPLE_RATE)
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
// The time of each phase is controled by the number of sample.
// 16 sample means the current phase is over and we can
// move forward to the next phase.

assign sampled_all = (sample_cnt == SAMPLE_RATE);
assign rst_buad = (tx_state == IDLE);

// state machine
always_ff @(posedge clk) begin
    if(rst) begin
        tx_state    <= IDLE;
    end
    else begin
        case(tx_state)
        IDLE: begin
            if (txvalid)
                tx_state <= START;
        end
        START: begin
            if (sampled_all)
                tx_state <= DATA;
        end
        DATA: begin
            if (data_cnt == 8)
                tx_state <= (cfg_parity[0]) ? PARITY : STOP;
        end
        PARITY: begin
            if (sampled_all)
                tx_state <= STOP;
        end
        STOP: begin
            if (sample_cnt == stop_cnt_static)
                tx_state <= IDLE;
        end
        endcase
    end
end

always_ff @(posedge clk) begin
    if(rst) begin
        data_cnt    <= 'b0;
        data        <= 'b0;
        sample_cnt  <= 'b0;
        parity      <= 'b0;
        uart_tx     <= 1'b1;
        ready       <= 1'b1;
        stop_cnt_static <= 'b0;
    end
    else begin
        stop_cnt_static <= (cfg_stop_bits == 2'b00) ? 16 : (cfg_stop_bits == 2'b01) ? 24 : 32;
        case(tx_state)
        IDLE: begin
                sample_cnt  <= 'b0;
                data        <= txdin;
                data_cnt    <= 'b0;
                ready       <= ~txvalid;
        end
        START: begin
            sample_cnt  <= sampled_all ? 'b0 : (sample ? sample_cnt + 1 : sample_cnt);
            uart_tx     <= 1'b0;
            parity      <= ^data;            // calculate parity here as the data is untouched here.
        end
        DATA: begin
            sample_cnt  <= sampled_all ? 'b0 : (sample ? sample_cnt + 1 : sample_cnt);
            data_cnt    <= sampled_all ? data_cnt + 1 : data_cnt;   // increase data count when sampled enough pulse.
            data        <= sampled_all ? data>>1 : data;
            uart_tx     <= data[0];                                 // send lsb first
        end
        PARITY: begin
            sample_cnt  <= sampled_all ? 'b0 : (sample ? sample_cnt + 1 : sample_cnt);
            uart_tx     <= cfg_parity[1] ^ parity;
        end
        STOP: begin
            sample_cnt  <= sample ? sample_cnt + 1 : sample_cnt;
            uart_tx     <= 1'b1;
            ready       <= (sample_cnt == stop_cnt_static) ? 1'b1 : 1'b0;
        end
        endcase
    end
end

endmodule