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
