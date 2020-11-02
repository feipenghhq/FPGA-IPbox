///////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 by Heqing Huang (feipenghhq@gamil.com)
//
// Project Name: N/A
// Module Name: I2C controller
//
// Author: Heqing Huang
// Date Created: 10/25/2020
//
// ================== Description ==================
//  A simple I2C controller master.
//
//  Version 1.0: 10/25/2020
//  Feature:
//   1. Configurable system clock and I2c clock frequency
//   2. Configurable byte size and number of byte. Does not support variable byte
//      length during each access. The number of by to be transfer must match with
//      the NUM_BYTE parameter
//   3. Only support write operation for now. Read will be added later
//
///////////////////////////////////////////////////////////////////////////////

module i2c_master #(
parameter       CLK_FREQ = 50,          // default 50  MHz system clock
parameter       I2C_CLK_FREQ = 100,     // default 100 KHz I2C clock
parameter       NUM_BYTE = 4,           // number of byte the controller needs to support, do not includes address/access
parameter       BYTE_SIZE = 8,          // byte size (assume address size + 1 = byte size)
parameter       DATA_WIDTH = NUM_BYTE * BYTE_SIZE
) (
input                           clk,   // assume 50Mhz clock, change the CLK_FREQ parameter for other clk freq.
input                           rst,

// User data interface
input                           req,        // input request, should be a pulse
input                           wen,        // 1 - write request, 0 - read request
input  [BYTE_SIZE-2:0]          slave_addr, // slave address, assume the size of the slave_addr is byte size -1
input  [DATA_WIDTH-1:0]         writedata,  // byte0, byte1, byte2, ...
output                          ready,

// I2C signal
input                           i2c_SDA_i,
output                          i2c_SDA_w,
output                          i2c_SDA_o,
output                          i2c_SCL_w,
output                          i2c_SCL_o,

// error
output                          i2c_slave_addr_err,    // slave address is not acked.
output                          i2c_slave_noack_err    // missing ack from slave err.
);

// ================================================
// Parameter
// ================================================

localparam ADDR_DATA_WIDTH = NUM_BYTE * BYTE_SIZE + BYTE_SIZE;
// number of sys clock in one i2c clock period used to count state transfer
localparam SYSCLK_COUNT    = (CLK_FREQ * 1000) / I2C_CLK_FREQ;

// ================================================
// Parameter Define
// ================================================

// I2C state machine
// =========================================
// I2C_IDLE  => IDLE state
// START => Start signal
// ADDR  => Transfer Address an W/R
// DATA  => Transfer Data
// I2C_STOP  => Stop signal
localparam  I2C_IDLE  = 0,
            I2C_START = 1,
            I2C_ADDR  = 2,
            I2C_DATA  = 3,
            I2C_STOP  = 4;
localparam  I2C_STATE_SIZE = I2C_STOP + 1;

// Data transfer state machine
// =========================================
// One-hot state mechine
// Bit 0 - Bit BYTE_SIZE - 1 => Transfer each bit, MSb first
// Bit BYTE_SIZE => ACK
localparam I2C_DATA_STATE_SIZE = BYTE_SIZE + 1;
localparam ACK_PHASE = BYTE_SIZE;

// ================================================
// Signal
// ================================================

// I2C signal
wire i2c_SDA_i_sysclk;
reg  i2c_SDA_w_q;
reg  i2c_SDA_o_q;
reg  i2c_SCL_w_q;
reg  i2c_SCL_o_q;
reg  i2c_SDA_w_next;
reg  i2c_SDA_o_next;
reg  i2c_SCL_w_next;
reg  i2c_SCL_o_next;

// State machine related signal
wire start;
wire i2c_clk_negedge;           // falling edge of i2c clock -> change state/data
wire i2c_clk_posedge;           // rising edge of i2c clock
wire i2c_clk_toggle;            // i2c clock toggle
wire i2c_start_byte_xfer;       // start a new byte
wire i2c_xfered_one_byte;       // transfered one byte
wire i2c_data_xfer_complete;    // complete data transfer

// clock divider counter
reg [$clog2(SYSCLK_COUNT)-1:0]   clk_divider;
wire                             clk_divider_run;

// internal data register
reg  [ADDR_DATA_WIDTH-1:0]   write_data;
reg  [ADDR_DATA_WIDTH-1:0]   write_data_next;
wire                         shift_data;
reg  [NUM_BYTE:0]            byte_count; // one-hot represent of num byte transfered


// i2c phase control and data xfer phase control
reg [I2C_STATE_SIZE-1:0]    i2c_state;
reg [BYTE_SIZE:0]           i2c_byte_state;
reg [I2C_STATE_SIZE-1:0]    i2c_state_next;
reg [BYTE_SIZE:0]           i2c_byte_state_next;

// ================================================
// I2C signal
// ================================================
assign  i2c_SDA_w = i2c_SDA_w_q;
assign  i2c_SDA_o = i2c_SDA_o_q;
assign  i2c_SCL_w = i2c_SCL_w_q;
assign  i2c_SCL_o = i2c_SCL_o_q;

// ================================================
// double sync flow to sync the input SDA signal
// ================================================
dsync sda_i_dsync (.Q(i2c_SDA_i_sysclk), .D(i2c_SDA_i), .clk(clk), .rst(rst));

// ================================================
// clock divider
// ================================================
assign clk_divider_run = ~i2c_state[I2C_IDLE]; // start running counter when we have request

always @(posedge clk) begin
    if      (rst)             clk_divider <= 'b0;
    else if (i2c_clk_posedge) clk_divider <= 'b0;   // reached SYSCLK_COUNT
    else if (clk_divider_run) clk_divider <= clk_divider + 1'd1;
    else                      clk_divider <= 'b0;
end

// ================================================
// I2C clock edge
// ================================================
assign i2c_clk_negedge = (clk_divider == SYSCLK_COUNT[$clog2(SYSCLK_COUNT)-1:0] / 2 - 1);
assign i2c_clk_posedge = (clk_divider == SYSCLK_COUNT[$clog2(SYSCLK_COUNT)-1:0] - 1);
assign i2c_clk_toggle = i2c_clk_posedge | i2c_clk_negedge;

// ================================================
// i2c state machine - NS
// ================================================
assign ready = i2c_state[I2C_IDLE];
assign start = req & ready;
assign i2c_data_xfer_complete = byte_count[NUM_BYTE];
assign i2c_xfered_one_byte = i2c_byte_state[ACK_PHASE] & i2c_clk_negedge;

// i2c_state logic
always @(*) begin
    i2c_state_next = 'b0;
    case(1)
        i2c_state[I2C_IDLE]: begin  // IDLE state
            if (start)  i2c_state_next[I2C_START] = 1'b1;
            else        i2c_state_next[I2C_IDLE] = 1'b1;
        end
        i2c_state[I2C_START]: begin // START state
            if (i2c_clk_negedge) i2c_state_next[I2C_ADDR] = 1'b1;
            else i2c_state_next[I2C_START] = 1'b1;
        end
        i2c_state[I2C_ADDR]: begin // ADDR state
            if (i2c_clk_negedge && i2c_xfered_one_byte) i2c_state_next[I2C_DATA] = 1'b1;
            else i2c_state_next[I2C_ADDR] = 1'b1;
        end
        i2c_state[I2C_DATA]: begin // DATA state
            if (i2c_clk_negedge && i2c_data_xfer_complete) i2c_state_next[I2C_STOP] = 1'b1;
            else i2c_state_next[I2C_DATA] = 1'b1;
        end
        i2c_state[I2C_STOP]: begin // STOP state
            if (i2c_clk_negedge) i2c_state_next[I2C_IDLE] = 1'b1;
            else i2c_state_next[I2C_STOP] = 1'b1;
        end
        default: i2c_state_next[I2C_IDLE] = 1'b1;
    endcase
end

assign i2c_start_byte_xfer = (i2c_clk_negedge & i2c_state[I2C_START]) |
                             (i2c_clk_negedge & (i2c_state[I2C_DATA] | i2c_state[I2C_ADDR]) & i2c_byte_state[ACK_PHASE]);

// i2c_byte_state logic
always @(*) begin
    i2c_byte_state_next = i2c_byte_state;
    if (i2c_start_byte_xfer) begin
        i2c_byte_state_next    = 'b0;
        i2c_byte_state_next[0] = 1'b1;
    end
    else if (i2c_clk_negedge) i2c_byte_state_next = i2c_byte_state_next << 1;
end

// sequential part
always @(posedge clk) begin
    if (rst) begin
        i2c_state           <= 'b0;
        i2c_state[I2C_IDLE] <= 1'b1;
        i2c_byte_state      <= 'b0;
    end
    else begin
        i2c_state       <= i2c_state_next;
        i2c_byte_state  <= i2c_byte_state_next;
    end
end

// ================================================
// i2c clk (SCL) generation
// ================================================

always @(*) begin
    i2c_SCL_o_next = i2c_SCL_o_q;
    i2c_SCL_w_next = i2c_SCL_w_q;
    if (i2c_state[I2C_IDLE]) begin
        i2c_SCL_o_next = 1'b1;
        i2c_SCL_w_next = 1'b0;
    end
    else if (i2c_state[I2C_STOP]) begin
        if (i2c_clk_posedge) i2c_SCL_o_next = 1'b1;
        i2c_SCL_w_next = 1'b1;
    end
    else begin
        if (i2c_clk_toggle) i2c_SCL_o_next = ~i2c_SCL_o_next;
        i2c_SCL_w_next = 1'b1;
    end
end

always @(posedge clk) begin
    if (rst) begin
        i2c_SCL_o_q <= 1'b1;
        i2c_SCL_w_q <= 1'b0;
    end
    else begin
        i2c_SCL_o_q <= i2c_SCL_o_next;
        i2c_SCL_w_q <= i2c_SCL_w_next;
    end
end

// ================================================
// i2c data (SDA) generation
// ================================================
always @(*) begin
    i2c_SDA_o_next = i2c_SDA_o_q;
    i2c_SDA_w_next = i2c_SDA_w_q;
    if (i2c_state[I2C_IDLE]) begin  // start condition
        if (start) begin
            i2c_SDA_w_next = 1'b1;
            i2c_SDA_o_next = 1'b0;
        end
        else begin
            i2c_SDA_w_next = 1'b0;
            i2c_SDA_o_next = 1'b1;
        end
    end
    else if (i2c_state[I2C_STOP]) begin // stop condition
        if (i2c_clk_negedge) i2c_SDA_o_next = 1'b1;
        i2c_SDA_w_next = 1'b1;
    end
    else begin  // transfer data or receive ACK
        if (i2c_byte_state[ACK_PHASE-1] & i2c_clk_negedge)  begin
            i2c_SDA_w_next = 1'b0;
            i2c_SDA_o_next = i2c_SDA_i_sysclk;
        end
        else begin
            if (i2c_clk_negedge) i2c_SDA_o_next = write_data[ADDR_DATA_WIDTH-1];
            if (i2c_clk_negedge) i2c_SDA_w_next = 1'b1;
        end
    end
end

always @(posedge clk) begin
    if (rst) begin
        i2c_SDA_o_q <= 1'b1;
        i2c_SDA_w_q <= 1'b0;
    end
    else begin
        i2c_SDA_o_q <= i2c_SDA_o_next;
        i2c_SDA_w_q <= i2c_SDA_w_next;
    end
end

// Shift data at SCL posedge and update SDA signal at SCL negedge.
// SDA will get the new data from the interal register
// But do not shift when we are in ACK phase
assign shift_data = i2c_clk_posedge & (i2c_state[I2C_ADDR] | i2c_state[I2C_DATA]) & ~i2c_byte_state[ACK_PHASE-1];

always @(*) begin
    write_data_next = write_data;
    // load new data
    if (start) write_data_next = {slave_addr, ~wen, writedata};
    else if (shift_data) write_data_next = write_data_next << 1;
end

always @(posedge clk) begin
    write_data <= write_data_next;
end

always @(posedge clk) begin
    if (rst) byte_count <= 'b1;
    else begin
        if (i2c_state[I2C_IDLE]) byte_count <= 'b1;
        else if (i2c_xfered_one_byte && i2c_state[I2C_DATA]) byte_count <= byte_count << 1'b1;
    end
end

assign i2c_slave_addr_err = i2c_state[I2C_ADDR] & i2c_byte_state[ACK_PHASE]
                            & i2c_clk_posedge & i2c_SDA_i_sysclk;
assign i2c_slave_noack_err = i2c_state[I2C_DATA] & i2c_byte_state[ACK_PHASE]
                            & i2c_clk_posedge & i2c_SDA_i_sysclk;

endmodule
