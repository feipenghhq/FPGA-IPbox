///////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 by Heqing Huang (feipenghhq@gamil.com)
//
// Project Name: WM8731/WM8731L Audio Controller
// Module Name: codec_transceiver_tb
//
// Author: Heqing Huang
// Date Created: 10/27/2020
//
// ================== Description ==================
//
//  Testbench for codec_transceiver
//
///////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ns

module audio_codec_transceiver_tb();

parameter CLK_RPED = 20;
parameter WIDTH  = 32;          // L + R channel: 16 + 16 => 32

parameter DELTA  = 2;   // need to be greater then the DELTA defined in codec_transceiver_bfm
parameter REPEAT = 10;

reg                   clk;
reg                   rst;
reg  [WIDTH-1:0]      dacdat_in;  // left + right channel
wire                  dacdat_req;
wire [WIDTH-1:0]      adcdat_out; // left + right channel
wire                  adcdat_vld;

wire                  bclk;
wire                  mclk;
wire                  daclrc;
wire                  dacdat;
wire                  adclrc;
wire                  adcdat;

wire [WIDTH-1:0]      received_dacdat;
wire [WIDTH-1:0]      golden_adcdat;

integer               error;
integer               i;
integer               j;

audio_codec_transceiver     DUT_audio_codec_transceiver (.*);
audio_codec_transceiver_bfm audio_codec_transceiver_bfm (.*);

// ================================================
// Main test
// ================================================
initial
begin
    i = 0;
    error = 0;
    rst = 1'b1;
    dacdat_in = 'b0;
    $display("Start the test at %t", $time);
    #100 @(posedge clk);
    #DELTA   rst = 1'b0;
    repeat (REPEAT) send();
    #1000;
    print_result();
    $finish();
end

initial
begin
    j = 0;
    wait(rst == 1'b1);
    repeat (REPEAT) receive();
end


task send;
begin
    wait(dacdat_req == 1);
    @(posedge clk);
    if (i > 0) begin    // skip the first few packet as we are establishing the protocal
        // test if the previous BFM received data is the same as the send data
        if (dacdat_in !== received_dacdat) begin
            $display("[ENV] ERROR - BFM received wrong data. Send %h, received %h at time %t",
                    dacdat_in, received_dacdat, $time);
            error = 1'b1;
        end
        else begin
            $display("[ENV] BFM received correct data %h at time %t", received_dacdat, $time);
        end
    end
    i = i + 1;
    // send new data
    #DELTA;
    dacdat_in = $random;
end
endtask

task receive;
begin
    wait(adcdat_vld == 1);
    @(posedge clk);
    if (j > 0) begin    // skip the first few packet as we are establishing the protocal
        // test if the previous BFM received data is the same as the send data
        if (adcdat_out !== golden_adcdat) begin
            $display("[ENV] ERROR - Received wrong data from BFM. BFM sent %h, but received %h at time %t",
                    golden_adcdat, adcdat_out, $time);
            error = 1'b1;
        end
        else begin
            $display("[ENV] Received correct data from BFM %h at time %t", adcdat_out, $time);
        end
    end
    j = j + 1;
    #DELTA;
end
endtask

// ================================================
// clock
// ================================================
initial
begin
    clk = 1;
    forever begin
        #(CLK_RPED/2) clk = ~clk;
    end
end

// ================================================
// Dump test
// ================================================
initial
begin
    $dumpfile("dump.vcd");
    $dumpvars(0, audio_codec_transceiver_tb);
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

