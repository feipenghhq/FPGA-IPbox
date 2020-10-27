///////////////////////////////////////////////////////////////////////////////
//
// Project Name: N/A
// Module Name: I2C controller
//
// Author: Heqing Huang
// Date Created: 10/25/2019
//
// ================== Description ==================
//
//
///////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ns

module i2c_master_tb();

parameter       CLK_FREQ = 50;
parameter       I2C_CLK_FREQ = 100;
parameter       NUM_BYTE = 4;
parameter       BYTE_SIZE = 8;
parameter       DATA_WIDTH = NUM_BYTE * BYTE_SIZE;

// ================================================
// DUT Signal
// ================================================
reg                           clk;
reg                           rst;
reg                           req;
reg                           wen;
reg  [BYTE_SIZE-2:0]          slave_addr;
reg  [DATA_WIDTH-1:0]         writedata;
//wire  [DATA_WIDTH-1:0]     readdata;
//wire                       rdata_vld;
wire                          ready;
wire                          i2c_slave_addr_err;
wire                          i2c_slave_noack_err;
// ================================================
// I2C BFM Signal
// ================================================
// received data and addr
wire [BYTE_SIZE-2:0] r_addr;
wire                 r_access;
wire [BYTE_SIZE-1:0] r_byte0;
wire [BYTE_SIZE-1:0] r_byte1;
wire [BYTE_SIZE-1:0] r_byte2;
wire [BYTE_SIZE-1:0] r_byte3;
wire                 complete;
wire  [DATA_WIDTH-1:0] bfm_writedata;
wire SDA;
wire SCL;

parameter DELTA = 2;

reg error;

// ================================================
// DUT and I2C BFM
// ================================================
// DUT
i2c_master dut_i2c_master(
    .i2c_SCL(SCL),
    .i2c_SDA(SDA),
    .*
);

// I2C BFM
i2c_slave_bfm i2c_slave_bfm(
    .i2c_SDA(SDA),
    .i2c_SCL(SCL),
    .*
);

assign bfm_writedata = {r_byte3, r_byte2, r_byte1, r_byte0};

pullup(SDA);
pullup(SCL);

// ================================================
// Main test
// ================================================
initial
begin
    $display("Start the test at %t", $time);
    rst = 1'b1;
    error = 1'b0;
    req = 1'b0;
    #100 @(posedge clk);
    #1   rst = 1'b0;
    #1000 @(posedge clk);
    I2C_write(1'b1, 7'b1010101, 32'hdeadbeef);
    I2C_write(1'b1, 7'b1110000, 32'habcdabcd);
    #1000;
    I2C_write(1'b1, 7'b1100110, 32'h11111111);
    #100 @(posedge clk);
    $display("Finished the test at %t", $time);
    print_result();
    $finish();
end

// ================================================
// clock
// ================================================
initial
begin
    clk = 1;
    forever begin
        #(CLK_FREQ/2) clk = ~clk;
    end
end

// ================================================
// Dump test
// ================================================
initial
begin
    $dumpfile("dump.vcd");
    $dumpvars(0, i2c_master_tb);
end

// ================================================
// input driven function
// ================================================
// support write operation for now
task I2C_write;
    input                           i_wen;
    input  [BYTE_SIZE-2:0]          i_slave_addr;
    input  [DATA_WIDTH-1:0]         i_writedata;
    begin
        $display();
        if (i_wen) $display("[DUT] Send write request at %t", $time);
        $display("[DUT] Slave address is 0x%h, data is 0x%h.", i_slave_addr, i_writedata);
        @(posedge clk);
        #DELTA;
        req         = 1'b1;
        wen         = i_wen;
        slave_addr  = i_slave_addr;
        writedata   = i_writedata;
        @(posedge clk);
        #DELTA;
        req         = 'b0;
        wen         = 'b0;
        slave_addr  = 'b0;
        writedata   = 'b0;
        wait(complete);
        if (r_addr != i_slave_addr) begin
            $display("[DUT]ERROR: BFM receives wrong address. BFM: 0x%h, DUT: 0x%h.",
                     i_slave_addr, r_addr);
            error = 1'b1;
        end
        else $display("[DUT] BFM receives correct address: 0x%h.", r_addr);
        if (bfm_writedata != i_writedata) begin
            $display("[DUT]ERROR: BFM receives wrong data. BFM: 0x%h, DUT: 0x%h.",
                     bfm_writedata, i_writedata);
            error = 1'b1;
        end
        else $display("[DUT] BFM receives correct data. BFM: 0x%h", i_writedata);
    end
endtask

    task print_result;
    begin
        if (error) begin
            $display("\n");
            $display("#####################################################");
            $display("#              Test Completes - Failed              #");
            $display("#####################################################");
        end
        else begin
            $display("\n");
            $display("#####################################################");
            $display("#             Test Completes - success              #");
            $display("#####################################################");
        end
    end
    endtask

endmodule

// I2C slave Bus-Function-Model
// The I2C BFM assumes that the I2C master will send 4 bytes.
module i2c_slave_bfm #(
    parameter       CLK_FREQ = 50,          // default 50  MHz system clock
    parameter       I2C_CLK_FREQ = 100,     // default 100 KHz I2C clock
    parameter       NUM_BYTE = 4,           // number of byte the controller needs to support, do not includes address/access
    parameter       BYTE_SIZE = 8,          // byte size (assume address size + 1 = byte size)
    parameter       DATA_WIDTH = NUM_BYTE * BYTE_SIZE
) (
    inout i2c_SDA,
    input i2c_SCL,
    // received data and addr
    output [BYTE_SIZE-2:0] r_addr,
    output                 r_access,
    output reg [BYTE_SIZE-1:0] r_byte0,
    output reg [BYTE_SIZE-1:0] r_byte1,
    output reg [BYTE_SIZE-1:0] r_byte2,
    output reg [BYTE_SIZE-1:0] r_byte3,
    output reg                 complete
);

parameter DELTA = 2;
integer i;

wire i2c_SDA_o;
wire i2c_SDA_i;
reg [BYTE_SIZE-1:0] addr_access;
reg i2c_SDA_w;

assign i2c_SDA = i2c_SDA_w ? 1'b0 : 1'bz;
assign i2c_SDA_i = i2c_SDA;

assign r_addr = addr_access[BYTE_SIZE-1:1];
assign r_access = addr_access[0];

always
begin
    i2c_SDA_w = 1'b0;
    complete = 1'b0;
    // Start condition
    wait(i2c_SCL == 1'b1);
    //wait(i2c_SDA == 1'b0);
    @(negedge i2c_SDA);
    #DELTA $display("[I2C BFM] SDA goes low. Start transaction at time %t", $time);
    // get the address
    receive_byte(addr_access);
    #DELTA $display("[I2C BFM] Received address: 0x%h at time %t", r_addr, $time);
    send_ack();
    // receive the next four byte
    receive_byte(r_byte3);
    #DELTA $display("[I2C BFM] Received byte3: 0x%h at time %t", r_byte3, $time);
    send_ack();
    receive_byte(r_byte2);
    #DELTA $display("[I2C BFM] Received byte2: 0x%h at time %t", r_byte2, $time);
    send_ack();
    receive_byte(r_byte1);
    #DELTA $display("[I2C BFM] Received byte1: 0x%h at time %t", r_byte1, $time);
    send_ack();
    receive_byte(r_byte0);
    send_ack();
    #DELTA $display("[I2C BFM] Received byte0: 0x%h at time %t", r_byte0, $time);
    wait(i2c_SCL == 1'b1);
    #DELTA $display("[I2C BFM] SCL goes high at time %t", $time);
    @(posedge i2c_SDA_i);
    #DELTA $display("[I2C BFM] SDA goes high at time %t", $time);
    complete = 1'b1;
    #DELTA $display("[I2C BFM] Transaction completed %t", $time);
end

// ================================================
// receive one byte
// ================================================
task receive_byte;
    output [BYTE_SIZE-1:0]  byte;
    begin
        byte = 0;
        i = 0;
        while (i < BYTE_SIZE) begin
            @(posedge i2c_SCL) begin
                byte = (byte << 1'b1) | i2c_SDA;
                i = i + 1;
            end
        end
    end
endtask

task send_ack;
    begin
        @(negedge i2c_SCL);
        #DELTA i2c_SDA_w = 1'b1;
        @(negedge i2c_SCL);
        #DELTA i2c_SDA_w = 1'b0; // release sda
    end
endtask

endmodule