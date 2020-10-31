///////////////////////////////////////////////////////////////////////////////
//
// Project Name: WM8731/WM8731L Audio Controller
// Module Name: audio_controller_tb
//
// Author: Heqing Huang
// Date Created: 10/27/2019
//
// ================== Description ==================
//
//  Testbench for audio_controller module
//
///////////////////////////////////////////////////////////////////////////////


`timescale 1ns/1ns

module audio_controller_tb();

parameter CLK_PRED = 20;

reg           clk;
reg           rst;

// register access interface
reg  [4:0]    sw_address = 0;
reg           sw_read = 0;
reg           sw_write = 0;
reg           sw_select = 0;
reg  [31:0]   sw_wrdata = 0;
wire [31:0]   sw_rddata;

wire          i2c_SDA_i;
wire          i2c_SDA_w;
wire          i2c_SDA_o;
wire          i2c_SCL_w;
wire          i2c_SCL_o;

// I2C signal
tri         i2c_SCL;
tri         i2c_SDA;

// Audio Codec interface
wire          bclk;
wire          mclk;
wire          daclrc;
wire          dacdat;
wire          adclrc;
wire          adcdat;

// user interface to ADC/DAC data
reg  [31:0]   dac_data_in;
reg           dac_data_wr;
wire          dac_fifo_full;
wire [31:0]   adc_data_out;
reg           adc_data_rd;
wire          adc_fifo_empty;


wire [32-1:0]  received_dacdat;
wire [32-1:0]  golden_adcdat;

integer error = 0;


audio_controller audio_controller(.*);
audio_codec_transceiver_bfm audio_codec_transceiver_bfm(.*);

assign SDA = i2c_SDA_w ? i2c_SDA_o : 1'bz;
assign SCL = i2c_SCL_w ? i2c_SCL_o : 1'bz;
assign i2c_SDA_i = SDA;

pullup(i2c_SCL);
pullup(i2c_SDA);

initial
begin
    rst = 1'b1;
    #100;
    @(posedge clk);
    #1
    rst = 1'b0;
    @(posedge clk);
    sw_write_op('h10, 31'h1FFFFFF);
    #10000000;
    $finish();
end


// ================================================
// clock
// ================================================
task sw_write_op;
    input [4:0] addr;
    input [31:0] data;
    begin
        $display("Avalon MM write access. Address: %d, Data %h", addr, data);
        #1;
        sw_address = addr;
        sw_read = 0;
        sw_write = 1;
        sw_wrdata = data;
        sw_select = 1;
        @(posedge clk);
        #1;
        sw_address = 0;
        sw_read = 0;
        sw_write = 0;
        sw_wrdata = 0;
        sw_select = 0;
    end
endtask

// ================================================
// clock
// ================================================
initial
begin
    clk = 1;
    forever begin
        #(CLK_PRED/2) clk = ~clk;
    end
end

// ================================================
// Dump test
// ================================================
initial
begin
    $dumpfile("dump.vcd");
    $dumpvars(0, audio_controller_tb);
end

// ================================================
// Task
// ================================================

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
