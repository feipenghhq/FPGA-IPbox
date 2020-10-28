///////////////////////////////////////////////////////////////////////////////
//
// Project Name: WM8731/WM8731L Audio Controller
// Module Name: audio_codec_transceiver_bfm
//
// Author: Heqing Huang
// Date Created: 10/27/2019
//
// ================== Description ==================
//
//  Audio Codec DACDAT/ADCDAT interface BFM
//
///////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ns

module audio_codec_transceiver_bfm #(
parameter DELTA  = 1,
parameter WIDTH  = 32           // L + R channel: 16 + 16 => 32
) (
// audio codec signal
input                   bclk,
input                   mclk,
input                   daclrc,
input                   dacdat,
input                   adclrc,
output                  adcdat,
output reg [WIDTH-1:0]  received_dacdat,
output [WIDTH-1:0]      golden_adcdat
);

reg [WIDTH/2-1:0]       dacdat_left;
reg [WIDTH/2-1:0]       dacdat_right;

reg                     adclrc_delay;
reg [WIDTH-1:0]         new_adcdat;
reg [WIDTH-1:0]         prev_adcdat;

// ================================================
// Receive data from FPGA
// ================================================
// update the received dacdat
always @(posedge daclrc) begin
    received_dacdat = {dacdat_left, dacdat_right};
    $display("[CODEC BFM] Received DATA: %h at time $t", received_dacdat, $time);
end

always @(posedge bclk) begin
    if (daclrc) begin // left channel
        #DELTA;
        dacdat_left = (dacdat_left << 1) | dacdat;
    end
    else begin // right channel
        #DELTA;
        dacdat_right = (dacdat_right << 1) | dacdat;
    end
end

// ================================================
// Send data to FPGA
// ================================================
assign golden_adcdat = prev_adcdat;
assign adcdat = new_adcdat[WIDTH-1];

// delay adclrc so the edge will not overlap with bclk
initial adclrc_delay = 1'b1;
always @(*) #DELTA adclrc_delay = adclrc;

always @(negedge bclk) begin
    new_adcdat = new_adcdat << 1;
end

always @(posedge adclrc_delay) begin
    new_adcdat = $random;
    $display("[CODEC BFM] Send DATA: %h at time %t", new_adcdat, $time);
    @(negedge bclk); // wait for the env to sample the data
    prev_adcdat = new_adcdat;
end

endmodule

