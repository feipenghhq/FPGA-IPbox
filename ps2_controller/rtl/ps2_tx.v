///////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 by Heqing Huang (feipenghhq@gamil.com)
//
// Project Name: PS2 Controller
// Module Name: ps2_tx
//
// Author: Heqing Huang
// Date Created: 11/04/2020
//
// ================== Description ==================
//
// 11/04/2020 - Version 1.0: Initial version
//
//  PS2 Transmittr core logic. Provides the PS2 interface from host to device
//
//
///////////////////////////////////////////////////////////////////////////////

module ps2_tx #(
parameter CLK = 50  // Clock period in MHz
) (
input               clk,
input               rst,

// PS2 interface
input               ps2_data_i,
output              ps2_data_o,
output              ps2_data_w,
input               ps2_clk_i,
output              ps2_clk_w,
output              ps2_clk_o,

// Host interface
input               rx_busy,    // RX path is busy
input               send_req,
input [7:0]         send_data,
output              send_idle
);

// ================================================
// State machine
// ================================================
localparam  IDLE  = 0,  // idle state_q
            RTS   = 1,  // request to send state0 - pull down the clock
            START = 2,  // start state_q
            DATA0 = 3,
            DATA1 = 4,
            DATA2 = 5,
            DATA3 = 6,
            DATA4 = 7,
            DATA5 = 8,
            DATA6 = 9,
            DATA7 = 10,
            PARITY = 11,    // parity state_q
            STOP = 12,  // stop state_q
            ACK = 13;

localparam  STATE_W = $clog2(ACK+1);
localparam  DELTA_MICROSECNOD = 100;    // pulling clock low for 100 microseconds
localparam  CLK_CNT = CLK * DELTA_MICROSECNOD;
localparam  CLK_CNT_WIDTH = $clog2(CLK_CNT+1);

// ================================================
// Signal
// ================================================

// state_q machine and OFL register
reg [STATE_W-1:0]   state_q;

reg [7:0]           send_data_q;
reg                 send_idle_q;
reg                 ps2_data_o_q;
reg                 ps2_data_w_q;
reg                 ps2_clk_w_q;

// logic signal
reg [7:0]           send_data_q_next;
reg                 send_idle_q_next;
reg                 ps2_clk_w_q_next;
reg                 ps2_data_o_q_next;
reg                 ps2_data_w_q_next;
reg [STATE_W-1:0]   state_next;

wire                ps2_data_i_sync;
wire                ps2_clk_i_sync;
wire                ps2_clk_negedge;

wire                req_vld;
wire                time_reached;

// other register
reg                 ps2_clk_i_sync_s1;
reg                 parity_q;
reg [CLK_CNT_WIDTH-1:0] clk_counter;

// other logic signal
reg                 parity_q_next;

// ================================================
// Assign output with internal register
// ================================================
assign ps2_clk_w = ps2_clk_w_q;
assign ps2_clk_o = 1'b0;    // always pull down the clock

assign ps2_data_o = ps2_data_o_q;
assign ps2_data_w = ps2_data_w_q;
assign send_idle  = send_idle_q;

// ================================================
// Sync the input and capture the edge
// ================================================
dsync   ps2_data_dsync(.Q(ps2_data_i_sync), .D(ps2_data_i), .clk(clk), .rst(rst));
dsync   ps2_clk_dsync(.Q(ps2_clk_i_sync), .D(ps2_clk_i), .clk(clk), .rst(rst));

always @(posedge clk) ps2_clk_i_sync_s1 <= ps2_clk_i_sync;

assign ps2_clk_negedge = ~ps2_clk_i_sync & ps2_clk_i_sync_s1;

// ================================================
// 100 microseconds conunter
// ================================================

always @(posedge clk) begin
    if (rst) clk_counter <= CLK_CNT[CLK_CNT_WIDTH-1:0];
    else if (time_reached) clk_counter <= CLK_CNT[CLK_CNT_WIDTH-1:0];
    else if (state_q == RTS) clk_counter <= clk_counter - 1'b1;
end

assign time_reached = ~(|clk_counter);

// ================================================
// State Machine Control
// ================================================

// For simplity
// We choose not to send when we request to hold the rx path
assign req_vld = ~rx_busy & send_req;

// hold state is handled by the RX path
always @(*) begin
    state_next = state_q;
    case(state_q)
        IDLE: if (req_vld) state_next = RTS;
        RTS : if (time_reached) state_next = START;  // pull clock low for at least 100 microseconds   
        START: if (ps2_clk_negedge) state_next = DATA0; // pulling data low then release the clock
        DATA0: if (ps2_clk_negedge) state_next = DATA1;
        DATA1: if (ps2_clk_negedge) state_next = DATA2;
        DATA2: if (ps2_clk_negedge) state_next = DATA3;
        DATA3: if (ps2_clk_negedge) state_next = DATA4;
        DATA4: if (ps2_clk_negedge) state_next = DATA5;
        DATA5: if (ps2_clk_negedge) state_next = DATA6;
        DATA6: if (ps2_clk_negedge) state_next = DATA7;
        DATA7: if (ps2_clk_negedge) state_next = PARITY;
        PARITY: if (ps2_clk_negedge) state_next = STOP;
        STOP: if (!ps2_clk_i_sync && !ps2_data_i_sync) state_next = ACK;
        ACK: if (ps2_clk_i_sync && ps2_data_i_sync) state_next = IDLE;        
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
    send_data_q_next = send_data_q;
    send_idle_q_next = send_idle_q;
    ps2_data_o_q_next = ps2_data_o_q;
    ps2_data_w_q_next = ps2_data_w_q;
    ps2_clk_w_q_next = ps2_clk_w_q;
    parity_q_next = parity_q;

    // use next state here so the OFL change aligns with the state change
    case(state_q)
        IDLE: begin
            send_idle_q_next = 1'b1;
            if (req_vld) begin
                send_data_q_next = send_data;
                ps2_clk_w_q_next = 1'b1;
                send_idle_q_next = 1'b0;
                parity_q_next = (^send_data) ^ 1'b1;
            end
        end
        RTS: begin  
            if (time_reached) begin
                ps2_clk_w_q_next = 1'b0;
                ps2_data_w_q_next = 1'b1;
                ps2_data_o_q_next = 1'b0;                
            end
        end
        START: begin
            if (ps2_clk_negedge) begin
                ps2_data_o_q_next = send_data_q[0];
                send_data_q_next = send_data_q >> 1'b1;
            end
        end
        DATA0: begin
            if (ps2_clk_negedge) begin
                ps2_data_o_q_next = send_data_q[0];
                send_data_q_next = send_data_q >> 1'b1;
            end
        end
        DATA1: begin
            if (ps2_clk_negedge) begin
                ps2_data_o_q_next = send_data_q[0];
                send_data_q_next = send_data_q >> 1'b1;
            end
        end
        DATA2: begin
            if (ps2_clk_negedge) begin
                ps2_data_o_q_next = send_data_q[0];
                send_data_q_next = send_data_q >> 1'b1;
            end
        end
        DATA3: begin
            if (ps2_clk_negedge) begin
                ps2_data_o_q_next = send_data_q[0];
                send_data_q_next = send_data_q >> 1'b1;
            end
        end
        DATA4: begin
            if (ps2_clk_negedge) begin
                ps2_data_o_q_next = send_data_q[0];
                send_data_q_next = send_data_q >> 1'b1;
            end
        end
        DATA5: begin
            if (ps2_clk_negedge) begin
                ps2_data_o_q_next = send_data_q[0];
                send_data_q_next = send_data_q >> 1'b1;
            end
        end
        DATA6: begin
            if (ps2_clk_negedge) begin
                ps2_data_o_q_next = send_data_q[0];
                send_data_q_next = send_data_q >> 1'b1;
            end
        end
        DATA7: begin
            if (ps2_clk_negedge) begin
                ps2_data_o_q_next = parity_q;
            end
        end
        PARITY: begin
            if (ps2_clk_negedge) begin
                ps2_data_w_q_next = 1'b0;
            end
        end
        // ideally we should check the ACK signal here.
        ACK: if (ps2_clk_i_sync && ps2_data_i_sync) send_idle_q_next = 1'b1;   

    endcase
end

always @(posedge clk) begin
    if (rst) begin
        send_data_q <= 'b0;
        send_idle_q <= 'b1;
        ps2_data_o_q <= 'b0;
        ps2_data_w_q <= 'b0;
        ps2_clk_w_q <= 'b0;
        parity_q <= 'b0;
    end
    else begin
        send_data_q <= send_data_q_next;
        send_idle_q <= send_idle_q_next;
        ps2_data_o_q <= ps2_data_o_q_next;
        ps2_data_w_q <= ps2_data_w_q_next;
        ps2_clk_w_q <= ps2_clk_w_q_next;
        parity_q <= parity_q_next;
    end
end

endmodule
