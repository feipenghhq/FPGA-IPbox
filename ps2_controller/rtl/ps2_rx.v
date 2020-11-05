///////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 by Heqing Huang (feipenghhq@gamil.com)
//
// Project Name: PS2 Controller
// Module Name: ps2_rx
//
// Author: Heqing Huang
// Date Created: 10/31/2020
//
// ================== Description ==================
//
// 10/31/2020 - Version 1.0: Initial version
//
//  PS2 Receiver core logic. Provides the PS2 interface from device to host
//
//
///////////////////////////////////////////////////////////////////////////////

module ps2_rx
(
input               clk,
input               rst,

// PS2 interface
input               ps2_data_i,
input               ps2_clk_i,
output              ps2_clk_w,
output              ps2_clk_o,

// Host interface
input               hold_req,           // request to hold
input               rx_en,              // enable the receiver path
output [7:0]        rcv_data,
output              rcv_parity_err,
output              rcv_vld,
output              rcv_idle
);

// ================================================
// State machine
// ================================================
localparam  IDLE  = 0,      // idle state_q
            START = 1,      // start state_q
            DATA0 = 2,
            DATA1 = 3,
            DATA2 = 4,
            DATA3 = 5,
            DATA4 = 6,
            DATA5 = 7,
            DATA6 = 8,
            DATA7 = 9,
            PARITY = 10,    // parity state_q
            STOP  = 11,     // stop state_q
            HOLD  = 12;     // host request to hold

localparam  STATE_W = $clog2(HOLD+1);

// ================================================
// Signal
// ================================================

// state_q machine and OFL register
reg [STATE_W-1:0]   state_q;
reg [7:0]           rcv_data_q;
reg                 rcv_vld_q;
reg                 rcv_parity_err_q;
reg                 rcv_idle_q;
reg                 ps2_clk_w_q;

// logic signal
reg [7:0]           rcv_data_q_next;
reg                 rcv_vld_q_next;
reg                 rcv_parity_err_q_next;
reg                 rcv_idle_q_next;
reg                 ps2_clk_w_q_next;
reg [STATE_W-1:0]   state_next;

wire                ps2_data_i_sync;
wire                ps2_clk_i_sync;
wire                ps2_clk_negedge;
wire                ps2_clk_posedge;

// other register
reg                 ps2_clk_i_sync_s1;

// ================================================
// Assign output with internal register
// ================================================
assign ps2_clk_w = ps2_clk_w_q;
assign ps2_clk_o = 1'b0;    // always pull down the clock

assign rcv_data         = rcv_data_q;
assign rcv_parity_err   = rcv_parity_err_q & rcv_vld;
assign rcv_vld          = rcv_vld_q;
assign rcv_idle         = rcv_idle_q;

// ================================================
// Sync the input and capture the edge
// ================================================
dsync   ps2_data_dsync(.Q(ps2_data_i_sync), .D(ps2_data_i), .clk(clk), .rst(rst));
dsync   ps2_clk_dsync(.Q(ps2_clk_i_sync), .D(ps2_clk_i), .clk(clk), .rst(rst));

always @(posedge clk) ps2_clk_i_sync_s1 <= ps2_clk_i_sync;

assign ps2_clk_negedge = ~ps2_clk_i_sync & ps2_clk_i_sync_s1;
assign ps2_clk_posedge = ps2_clk_i_sync & ~ps2_clk_i_sync_s1;

// ================================================
// State Machine Control
// ================================================
always @(*) begin
    state_next = state_q;
    case(state_q)
        IDLE: begin
            // go to HOLD state_q when we get a hold request
            if (hold_req)   state_next = HOLD;
            // data goes low while clock is high
            else if (!ps2_data_i_sync && ps2_clk_i_sync && rx_en)
                state_next = START;
        end
        START: if (ps2_clk_posedge) state_next = DATA0;
        DATA0: if (ps2_clk_posedge) state_next = DATA1;
        DATA1: if (ps2_clk_posedge) state_next = DATA2;
        DATA2: if (ps2_clk_posedge) state_next = DATA3;
        DATA3: if (ps2_clk_posedge) state_next = DATA4;
        DATA4: if (ps2_clk_posedge) state_next = DATA5;
        DATA5: if (ps2_clk_posedge) state_next = DATA6;
        DATA6: if (ps2_clk_posedge) state_next = DATA7;
        DATA7: if (ps2_clk_posedge) state_next = PARITY;
        PARITY: if (ps2_clk_posedge) state_next = STOP;
        STOP: if (ps2_clk_posedge) state_next = IDLE;
        HOLD: if (!hold_req) state_next = IDLE;
        default: state_next = state_q;
    endcase
end

always @(posedge clk) begin
    if (rst) begin
        state_q <= IDLE;
    end
    else begin
        state_q <= state_next;
    end
end

// ================================================
// Output Function Logic
// ================================================

always @(*) begin
    rcv_vld_q_next = 1'b0;
    rcv_data_q_next = rcv_data_q;
    rcv_parity_err_q_next = rcv_parity_err_q;
    rcv_idle_q_next = rcv_idle_q;
    ps2_clk_w_q_next = ps2_clk_w_q;

    // use next state here so the OFL change aligns with the state change
    case(state_q)
        IDLE: begin
            rcv_data_q_next = 8'b0;
            rcv_parity_err_q_next = 1'b0;
            rcv_idle_q_next = 1'b1;
            ps2_clk_w_q_next = 1'b0;
        end
        START: rcv_idle_q_next = 1'b0;
        DATA0: if (ps2_clk_negedge) rcv_data_q_next = {ps2_data_i_sync, rcv_data_q_next[7:1]};
        DATA1: if (ps2_clk_negedge) rcv_data_q_next = {ps2_data_i_sync, rcv_data_q_next[7:1]};
        DATA2: if (ps2_clk_negedge) rcv_data_q_next = {ps2_data_i_sync, rcv_data_q_next[7:1]};
        DATA3: if (ps2_clk_negedge) rcv_data_q_next = {ps2_data_i_sync, rcv_data_q_next[7:1]};
        DATA4: if (ps2_clk_negedge) rcv_data_q_next = {ps2_data_i_sync, rcv_data_q_next[7:1]};
        DATA5: if (ps2_clk_negedge) rcv_data_q_next = {ps2_data_i_sync, rcv_data_q_next[7:1]};
        DATA6: if (ps2_clk_negedge) rcv_data_q_next = {ps2_data_i_sync, rcv_data_q_next[7:1]};
        DATA7: if (ps2_clk_negedge) rcv_data_q_next = {ps2_data_i_sync, rcv_data_q_next[7:1]};
        PARITY: begin
            if (ps2_clk_negedge)
                rcv_parity_err_q_next = (^rcv_data_q) ^ ps2_data_i_sync ^ 1'b1;
        end
        STOP: begin
            if (ps2_clk_posedge) rcv_vld_q_next = 1'b1;
        end
        HOLD: begin
            rcv_idle_q_next = 1'b0;
            ps2_clk_w_q_next = 1'b1;
        end
    endcase
end

always @(posedge clk) begin
    if (rst) begin
        rcv_data_q <= 'b0;
        rcv_vld_q  <= 'b0;
        rcv_parity_err_q  <= 'b0;
        rcv_idle_q <= 'b0;
        ps2_clk_w_q <= 'b0;
    end
    else begin
        rcv_data_q <= rcv_data_q_next;
        rcv_vld_q  <= rcv_vld_q_next;
        rcv_parity_err_q  <= rcv_parity_err_q_next;
        rcv_idle_q <= rcv_idle_q_next;
        ps2_clk_w_q <= ps2_clk_w_q_next;
    end
end

endmodule
