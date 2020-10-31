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
parameter SYSCLK = 50,          // System clock rate in MHz
parameter MCLK   = 12.5,        // MCLK clock rate in MHz round 12.288 to 12.5
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

localparam SAMPLE_RATE    = 0.048;          // 48K sample rate
localparam BCLK           = WIDTH * SAMPLE_RATE;    // bclk freqeuncy
/* verilator lint_off REALCVT */
localparam BCLK_CNT       = rtoi(SYSCLK / BCLK);
localparam MCLK_CNT       = rtoi(SYSCLK / MCLK); // clock counter to generate the MCLK
/* verilator lint_on REALCVT */
localparam MCLK_CNT_WIDTH = $clog2(MCLK_CNT+1);
localparam BCLK_CNT_WIDTH = $clog2(BCLK_CNT+1);
localparam LRC_CNT_WIDTH  = $clog2(WIDTH+1);

initial $display("MCLK_CNT = %d", MCLK_CNT);

// ================================================
// Signal
// ================================================
reg [MCLK_CNT_WIDTH-1:0]    mclk_counter;   // MCLK clock counter
wire                        mclk_posedge;
wire                        mclk_negedge;
reg [BCLK_CNT_WIDTH-1:0]    bclk_counter;   // BCLK clock counter
wire                        bclk_posedge;
wire                        bclk_negedge;
reg [LRC_CNT_WIDTH-1:0]     lrc_counter;   // right/left clock counter
wire                        lrc_posedge;
wire                        lrc_negedge;

reg [WIDTH-1:0]     dacdat_q;
reg [WIDTH-1:0]     adcdat_q;
reg                 mclk_q;
reg                 bclk_q;
reg                 lrc_q;
reg                 one_xfer_done;
reg                 dacdat_req_q;
reg                 dacdat_req_q_s1;
wire                adcdat_sysclk;    // synced adcdat input

// ================================================
// Assign output to internal register
// ================================================
assign bclk = bclk_q;
assign mclk = mclk_q;
assign daclrc = lrc_q;
assign dacdat = dacdat_q[WIDTH-1];
assign adclrc = lrc_q;
assign adcdat_vld = one_xfer_done;
assign adcdat_out = adcdat_q;
assign dacdat_req = dacdat_req_q;

// ================================================
// Clock counter and MCLK/BCLK generation
// ================================================
// BCLK/MCLK starts from reset
//               ___     ___
//  CLK  _______/   \___/   \___
//       ___
//  RST     \___________________
//

// MCLK
always @(posedge clk) begin
    if (rst || mclk_negedge) mclk_counter <= 'b0;
    else                     mclk_counter <= mclk_counter + 1'b1;
end

assign mclk_posedge = (mclk_counter == MCLK_CNT[MCLK_CNT_WIDTH-1:0] / 2 - 1);
assign mclk_negedge = (mclk_counter == MCLK_CNT[MCLK_CNT_WIDTH-1:0] - 1);

always @(posedge clk) begin
    if      (rst)         mclk_q <= 1'b0;
    else if (mclk_posedge) mclk_q <= 1'b1;
    else if (mclk_negedge) mclk_q <= 1'b0;
end

// BCLK
always @(posedge clk) begin
    if (rst || bclk_negedge) bclk_counter <= 'b0;
    else                     bclk_counter <= bclk_counter + 1'b1;
end

assign bclk_posedge = (bclk_counter == BCLK_CNT[BCLK_CNT_WIDTH-1:0] / 2 - 1);
assign bclk_negedge = (bclk_counter == BCLK_CNT[BCLK_CNT_WIDTH-1:0] - 1);

always @(posedge clk) begin
    if      (rst)         bclk_q <= 1'b0;
    else if (bclk_posedge) bclk_q <= 1'b1;
    else if (bclk_negedge) bclk_q <= 1'b0;
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
    else if (bclk_negedge) begin
        if (lrc_posedge) lrc_counter <= 'b0;
        else             lrc_counter <= lrc_counter + 1'b1;
    end
end

assign lrc_negedge = bclk_negedge & (lrc_counter == (WIDTH / 2 - 1));
assign lrc_posedge = bclk_negedge & (lrc_counter == (WIDTH - 1));

always @(posedge clk) begin
    if      (rst)        lrc_q <= 1'b1;
    else if (lrc_posedge) lrc_q <= 1'b1;
    else if (lrc_negedge) lrc_q <= 1'b0;
end

// ================================================
// Data send/receive generation
// ================================================

dsync adcdat_dsync (.Q(adcdat_sysclk), .D(adcdat), .clk(clk), .rst(rst));

always @(posedge clk) begin
    one_xfer_done <= lrc_posedge;
    // ADC DATA
    //if (adcdat_vld) adcdat_q <= 'b0;
    //else if (bclk_posedge) adcdat_q <= {adcdat_q[WIDTH-2:0] , adcdat_sysclk};
    if (bclk_posedge) adcdat_q <= {adcdat_q[WIDTH-2:0] , adcdat_sysclk};

    // ADC DATA
    // ask for the ne dac data 2  cycles before we change to LCR clock. Why 2 cycles?
    // request goes out => 1 clock (req is flopped here)
    // data come in and get flopped =>1 clock
    dacdat_req_q <= (lrc_counter == (WIDTH - 1)) & (bclk_counter == BCLK_CNT[BCLK_CNT_WIDTH-1:0] - 3) ;
    dacdat_req_q_s1 <= dacdat_req_q;
    if (dacdat_req_q_s1) dacdat_q <= dacdat_in; // data comes the next cycle after dacdat_req
    else if (bclk_negedge) dacdat_q <= dacdat_q << 1;
end

function integer rtoi;
    input integer x;
    begin
        rtoi = x;
    end
endfunction

endmodule

