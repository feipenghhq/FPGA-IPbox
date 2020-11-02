///////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 by Heqing Huang (feipenghhq@gamil.com)
//
// Project Name: WM8731/WM8731L Audio Controller
// Module Name: audio_controller_csr_tb
//
// Author: Heqing Huang
// Date Created: 10/27/2020
//
// ================== Description ==================
//
//  Testbench for audio_controller_csr module
//
///////////////////////////////////////////////////////////////////////////////


`timescale 1ns/1ns

module audio_controller_csr_tb();


parameter CLK_FREQ = 50;

reg            clk;
reg            reset;
reg  [4:0]     i_sw_address;
reg            i_sw_read;
reg            i_sw_write;
reg            i_sw_select;
reg  [31:0]    i_sw_wrdata;
wire [31:0]    o_sw_rddata;
reg            i_hw_status_i2c_idle;
reg            i_hw_status_dac_fifo_full;
reg            i_hw_status_adc_fifo_empty;
wire           o_hw_ctrl_dac_sel;
wire           o_hw_ctrl_adc_sel;
wire [23:0]    o_hw_i2c_ctrl_data;
wire           o_hw_i2c_ctrl_write;

wire           o_hw_adc_data_data_fifo_read;
reg [31:0]     i_hw_adc_data_data_fifo_read_data;
wire           o_hw_dac_data_data_fifo_write;
wire [31:0]    o_hw_dac_data_data_fifo_write_data;
reg  [31:0]    dac_fifo_write_data;

reg  [31:0]    wirte_data;
reg  [31:0]    read_data;
reg  o_hw_ctrl_dac_sel_expected;
reg  o_hw_ctrl_adc_sel_expected;

integer        error;


always @(*) begin
    if (o_hw_dac_data_data_fifo_write)
        dac_fifo_write_data <= o_hw_dac_data_data_fifo_write_data;
end

initial
begin
    // drive some default register value different from reset value
    i_hw_status_i2c_idle = 0;
    i_hw_status_dac_fifo_full = 1;
    i_hw_status_adc_fifo_empty = 0;
    i_hw_adc_data_data_fifo_read_data = 32'h0;
    // AVM
    i_sw_address = 0;
    i_sw_read = 0;
    i_sw_write = 0;
    i_sw_select = 1;
    i_sw_wrdata = 0;
    reset = 1'b1;
    #100;
    @(posedge clk);
    #1;
    reset = 1'b0;
    @(posedge clk);
    // read the register value to check hw status
    avm_read_op('h0, 32'h2);
    read_data = $random;
    i_hw_adc_data_data_fifo_read_data = read_data;
    avm_read_op('h8, read_data);
    // write the register value and check hw output
    wirte_data = $random;
    o_hw_ctrl_dac_sel_expected = wirte_data[0];
    o_hw_ctrl_adc_sel_expected = wirte_data[1];
    avm_write_op('h4, wirte_data);
    wirte_data = $random;
    avm_write_op('hc, wirte_data);
    if (o_hw_ctrl_dac_sel_expected !== o_hw_ctrl_dac_sel) error = error + 1;
    if (o_hw_ctrl_adc_sel_expected !== o_hw_ctrl_adc_sel) error = error + 1;
    if (wirte_data !== dac_fifo_write_data) error = error + 1;
    $display("Expected o_hw_ctrl_dac_sel: %h, Actual: %h", o_hw_ctrl_dac_sel_expected, o_hw_ctrl_dac_sel);
    $display("Expected o_hw_ctrl_adc_sel: %h, Actual: %h", o_hw_ctrl_adc_sel_expected, o_hw_ctrl_adc_sel);
    $display("Expected o_hw_dac_data_data: %h, Actual: %h", wirte_data, dac_fifo_write_data);
    #100;
    print_result();
    $finish();
end


audio_controller_csr audio_controller_csr(.*);

task avm_write_op;
    input [18:0] addr;
    input [31:0] data;
    begin
        #1;
        $display("Avalon MM write access. Address: %d, Data %h", addr, data);
        i_sw_address = addr;
        i_sw_read = 0;
        i_sw_write = 1;
        i_sw_wrdata = data;
        @(posedge clk);
        #1;
        i_sw_address = 0;
        i_sw_read = 0;
        i_sw_write = 0;
        i_sw_wrdata = 0;
    end
endtask

task avm_read_op;
    input [18:0] addr;
    input [31:0] expected;
    begin
        #1;
        $display("Avalon MM read access.  Address: %d", addr);
        i_sw_address = addr;
        i_sw_read = 1;
        i_sw_write = 0;
        @(posedge clk);
        #1;
        i_sw_address = 0;
        i_sw_read = 0;
        i_sw_write = 0;
        #1;
        if (expected !== o_sw_rddata) begin
            $display("ERROR: Read data mismatch. Address: %d, Expected Data %h, Actual Data %h",
                      addr, expected, o_sw_rddata);
            error = 1;
        end
        else begin
            $display("Read data matches.      Address: %d, Expected Data %h, Actual Data %h",
                      addr, expected, o_sw_rddata);
        end
    end
endtask


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
    $dumpvars(0, audio_controller_csr_tb);
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
