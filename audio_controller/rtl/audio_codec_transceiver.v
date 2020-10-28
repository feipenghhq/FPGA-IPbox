///////////////////////////////////////////////////////////////////////////////
//
// Project Name: WM8731/WM8731L Audio Controller
// Module Name: audio_codec_transceiver
//
// Author: Heqing Huang
// Date Created: 10/27/2019
//
// ================== Description ==================
//
//  Receives and transfers data between audio codec chip and the FPGA
//  This design use the following feature for the audio codec ship:
//  1. Left-justified mode
//  2. Slave clocking mode (BCLK driven by FPGA)
//  3. Master clock rate of 12.288Mhz
//  4. Resolution of 16 bits
//  5. Sampling rate of 48K samples per second
//
///////////////////////////////////////////////////////////////////////////////

module audio_codec_transceiver #(
parameter SYSCLK = 50000,       // System clock rate in KHz
parameter MCLK   = 12288,       // MCLK clock rate in KHz
parameter WIDTH  = 32           // L + R channel: 16 + 16 => 32
) (

// user side signal
input                   clk,
input                   rst,
input  [WIDTH-1:0]      dacdat_in,  // left + right channel
output                  dacdat_req,
output [WIDTH-1:0]      adcdat_out, // left + right channel
output                  adcdat_vld,

// audio codec signal
output                  bclk,
output                  mclk,
output                  daclrc,
output                  dacdat,
output                  adclrc,
input                   adcdat
);

// ================================================
// Parameter
// ================================================
localparam MCLK_CNT       = 50000 * 1000 / 12288; // clock counter to generate the MCLK
localparam MCLK_CNT_WIDTH = $clog2(MCLK_CNT+1);
localparam LRC_CNT_WIDTH  = $clog2(WIDTH);

// ================================================
// Signal
// ================================================
reg [MCLK_CNT_WIDTH-1:0]    mclk_counter;   // clock counter
wire                        mclk_posedge;
wire                        mclk_negedge;
wire                        mclk_toggle;
reg [LRC_CNT_WIDTH-1:0]     lrc_counter;   // right/left clock counter
wire                        lrc_posedge;
wire                        lrc_negedge;
wire                        lrc_toggle;

reg [WIDTH-1:0]     dacdat_q;
reg [WIDTH-1:0]     adcdat_q;
reg                 mclk_q;
reg                 lrc_q;
reg                 adcdat_vld_q;
reg                 dacdat_req_q;
reg                 dacdat_req_q_s1;
wire                adcdat_sysclk;    // synced adcdat input

// ================================================
// Assign output to internal register
// ================================================
assign bclk = mclk_q;
assign mclk = mclk_q;
assign daclrc = lrc_q;
assign dacdat = dacdat_q[WIDTH-1];
assign adclrc = lrc_q;
assign adcdat_vld = adcdat_vld_q;
assign adcdat_out = adcdat_q;
assign dacdat_req = dacdat_req_q;

// ================================================
// Clock counter and MCLK/BCLK generation
// ================================================
// BCLK/MCLK starts from reset
//               ___     ___
// MCLK  _______/   \___/   \___
//       ___
// RST      \___________________
//
always @(posedge clk) begin
    if (rst || mclk_negedge) mclk_counter <= 'b0;
    else                     mclk_counter <= mclk_counter + 1'b1;
end

assign mclk_posedge = (mclk_counter == MCLK_CNT[MCLK_CNT_WIDTH-1:0] / 2);
assign mclk_negedge = (mclk_counter == MCLK_CNT[MCLK_CNT_WIDTH-1:0]);
assign mclk_toggle = mclk_negedge | mclk_posedge;

always @(posedge clk) begin
    if      (rst)         mclk_q <= 1'b0;
    else if (mclk_toggle) mclk_q <= ~mclk_q;
end

// lrc clock
// LRC starts from reset
//           | L | R | L | R |
//       ________     ___     _
// LRC           \___/   \___/
//       ___
// RST      \___________________
//
always @(posedge clk) begin
    if (rst) lrc_counter <= 'b0;
    else if (mclk_negedge) begin
        if (lrc_posedge) lrc_counter <= 'b0;
        else             lrc_counter <= lrc_counter + 1'b1;
    end
end

assign lrc_negedge = mclk_negedge & (lrc_counter == (WIDTH[LRC_CNT_WIDTH-1:0] / 2 - 1));
assign lrc_posedge = mclk_negedge & (lrc_counter == (WIDTH[LRC_CNT_WIDTH-1:0] - 1));
assign lrc_toggle  = lrc_posedge | lrc_negedge;

always @(posedge clk) begin
    if      (rst)        lrc_q <= 1'b1;
    else if (lrc_toggle) lrc_q <= ~lrc_q;
end

// ================================================
// Data send/receive generation
// ================================================

dsync adcdat_dsync (.Q(adcdat_sysclk), .D(adcdat), .clk(clk), .rst(rst));

always @(posedge clk) begin
    // ADC DATA
    if (mclk_posedge) adcdat_q <= {adcdat_q[WIDTH-2:0] , adcdat_sysclk};
    adcdat_vld_q <= lrc_posedge;

    // DAC DATA
    dacdat_req_q <= lrc_posedge;
    dacdat_req_q_s1 <= dacdat_req_q;
    if (dacdat_req_q_s1) dacdat_q <= dacdat_in; // data comes the next cycle after dacdat_req
    else if (mclk_negedge) dacdat_q <= dacdat_q << 1;
end

endmodule

