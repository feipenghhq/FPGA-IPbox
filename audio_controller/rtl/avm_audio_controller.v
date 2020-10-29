///////////////////////////////////////////////////////////////////////////////
//
// Project Name: WM8731/WM8731L Audio Controller
// Module Name: avm_audio_controller
//
// Author: Heqing Huang
// Date Created: 10/28/2019
//
// ================== Description ==================
//
// Avalon Memory Mapped Interface Wrapper for
// Audio controller for WM8731/WM8731L chip
//
///////////////////////////////////////////////////////////////////////////////

module avm_audio_controller #(
parameter SYSCLK = 50
) (
// clock and reset
input           clk,
input           rst,
// Avalon MM slave interface
input  [4:0]    avm_address,
input           avm_select,
input           avm_read,
input           avm_write,
input  [31:0]   avm_writedata,
output [31:0]   avm_readdata,
// I2C signal
inout           i2c_SCL,
inout           i2c_SDA,
// Audio Codec interface
output          bclk,
output          mclk,
output          daclrc,
output          dacdat,
output          adclrc,
input           adcdat,
// user interface to ADC/DAC data
input  [31:0]   dac_data_in,
input           dac_data_wr,
output          dac_fifo_full,
output [31:0]   adc_data_out, // This data is from FWFT FIFO so data is avaliable
                              // at same cycle when adc_data_rd is asserted
input           adc_data_rd,
output          adc_fifo_empty
);

// glue logic for sw_select
//wire    avm_select;
//assign  avm_select = avm_read | avm_write;

audio_controller #(.SYSCLK(SYSCLK))
audio_controller(
    .clk            (clk         ),
    .rst            (rst         ),
    .sw_address     (avm_address  ),
    .sw_read        (avm_read     ),
    .sw_write       (avm_write    ),
    .sw_select      (avm_select   ),
    .sw_wrdata      (avm_writedata),
    .sw_rddata      (avm_readdata ),
    .i2c_SCL        (i2c_SCL     ),
    .i2c_SDA        (i2c_SDA     ),
    .bclk           (bclk        ),
    .mclk           (mclk        ),
    .daclrc         (daclrc      ),
    .dacdat         (dacdat      ),
    .adclrc         (adclrc      ),
    .adcdat         (adcdat      ),
    .dac_data_in    (dac_data_in ),
    .dac_data_wr    (dac_data_wr ),
    .adc_data_out   (adc_data_out),
    .adc_data_rd    (adc_data_rd ),
    .dac_fifo_full  (dac_fifo_full),
    .adc_fifo_empty (adc_fifo_empty)
);

endmodule
