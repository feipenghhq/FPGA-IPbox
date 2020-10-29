///////////////////////////////////////////////////////////////////////////////
//
// Project Name: WM8731/WM8731L Audio Controller
// Module Name: audio_controller
//
// Author: Heqing Huang
// Date Created: 10/27/2019
//
// ================== Description ==================
//
// Audio controller for WM8731/WM8731L chip
//
///////////////////////////////////////////////////////////////////////////////

module audio_controller #(
parameter SYSCLK = 50       // System clock rate in MHz
) (

// clock and reset
input           clk,
input           rst,

// register access interface
input  [4:0]    sw_address,
input           sw_read,
input           sw_write,
input           sw_select,
input  [31:0]   sw_wrdata,
output [31:0]   sw_rddata,

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

// ================================================
// Parameter
// ================================================
parameter DAC_FROM_CPU = 0;
parameter ADC_FROM_CPU = 0;

// ================================================
// Signal
// ================================================

// CSR signal
wire            hw_status_i2c_idle;
wire            hw_status_dac_fifo_full;
wire            hw_status_adc_fifo_empty;
wire            hw_ctrl_dac_sel;
wire            hw_ctrl_adc_sel;
wire [23:0]     hw_i2c_ctrl_data;
wire            hw_i2c_ctrl_write;
wire            hw_adc_data_data_fifo_read;
wire [31:0]     hw_adc_data_data_fifo_read_data;
wire            hw_dac_data_data_fifo_write;
wire [31:0]     hw_dac_data_data_fifo_write_data;


// I2C related signal
reg             hw_i2c_ctrl_write_s1;
wire            hw_i2c_ctrl_write_posedge;
wire [6:0]      i2c_slave_addr;
wire [15:0]     i2c_writedata;
wire            i2c_ready;
wire            i2c_wen;

// DAC FIFO related signal
wire            dac_fifo_read;
wire [31:0]     dac_fifo_read_data;
wire            dac_fifo_write;
wire [31:0]     dac_fifo_write_data;


// ADC FIFO related signal
wire            adc_fifo_read;
wire [31:0]     adc_fifo_read_data;
wire            adc_fifo_write;
wire [31:0]     adc_fifo_write_data;

// Audio Codec related signal
wire [31:0]     dacdat_in;
wire            dacdat_req;
wire [31:0]     adcdat_out;
wire            adcdat_vld;

// ================================================
// Glue Logic
// ================================================

// Detect the risint edge of the hw_i2c_ctrl_write signal
always @(posedge clk) begin
    hw_i2c_ctrl_write_s1 <= hw_i2c_ctrl_write;
end
assign hw_i2c_ctrl_write_posedge = hw_i2c_ctrl_write & ~hw_i2c_ctrl_write_s1;

// Wire connection - I2C
assign i2c_slave_addr = hw_i2c_ctrl_data[6:0];
assign i2c_wen        = hw_i2c_ctrl_data[7] & hw_i2c_ctrl_write_posedge;
assign i2c_writedata  = hw_i2c_ctrl_data[23:8];
assign hw_status_i2c_idle = i2c_ready;

// Wire connection - DAC FIFO
assign dac_fifo_read  = dacdat_req;
assign dacdat_in      = dac_fifo_read_data;
assign dac_fifo_write_data = (hw_ctrl_dac_sel == DAC_FROM_CPU) ? hw_dac_data_data_fifo_write_data :
                             dac_data_in;
assign dac_fifo_write      = (hw_ctrl_dac_sel == DAC_FROM_CPU) ? hw_dac_data_data_fifo_write :
                             dac_data_wr;

// Wire connection - ADC FIFO
assign adc_fifo_write = adcdat_vld;
assign adc_fifo_write_data = adcdat_out;
assign adc_fifo_read = (hw_ctrl_adc_sel == ADC_FROM_CPU) ? hw_adc_data_data_fifo_read :
                        adc_data_rd;
assign adc_data_out = adc_fifo_read_data;
assign hw_adc_data_data_fifo_read_data = adc_fifo_read_data;

// Wire connection - CSR
assign hw_status_dac_fifo_full = dac_fifo_full;
assign hw_status_adc_fifo_empty = adc_fifo_empty;



// ================================================
// Module Instantiation
// ================================================


// CSR module
audio_controller_csr audio_controller_csr
(
    .clk                        (clk),
    .reset                      (rst),
    .i_sw_address               (sw_address),
    .i_sw_read                  (sw_read),
    .i_sw_write                 (sw_write),
    .i_sw_select                (sw_select),
    .i_sw_wrdata                (sw_wrdata),
    .o_sw_rddata                (sw_rddata),
    .i_hw_status_i2c_idle       (hw_status_i2c_idle),
    .i_hw_status_dac_fifo_full  (hw_status_dac_fifo_full),
    .i_hw_status_adc_fifo_empty (hw_status_adc_fifo_empty),
    .o_hw_ctrl_dac_sel          (hw_ctrl_dac_sel),
    .o_hw_ctrl_adc_sel          (hw_ctrl_adc_sel),
    .o_hw_i2c_ctrl_data         (hw_i2c_ctrl_data),
    .o_hw_i2c_ctrl_write        (hw_i2c_ctrl_write),
    .o_hw_adc_data_data_fifo_read      (hw_adc_data_data_fifo_read),
    .i_hw_adc_data_data_fifo_read_data (hw_adc_data_data_fifo_read_data),
    .o_hw_dac_data_data_fifo_write     (hw_dac_data_data_fifo_write),
    .o_hw_dac_data_data_fifo_write_data(hw_dac_data_data_fifo_write_data)
);


// i2c controller
i2c_master #(.CLK_FREQ(SYSCLK), .NUM_BYTE(2), .BYTE_SIZE(8))
i2c_master (
    .clk                    (clk),
    .rst                    (rst),
    .req                    (hw_i2c_ctrl_write_posedge),
    .wen                    (i2c_wen),
    .slave_addr             (i2c_slave_addr),
    .writedata              (i2c_writedata),
    .ready                  (i2c_ready),
    .i2c_SCL                (i2c_SCL),
    .i2c_SDA                (i2c_SDA),
    // verilator lint_off PINCONNECTEMPTY
    .i2c_slave_addr_err     (),
    .i2c_slave_noack_err    ()
    // verilator lint_on PINCONNECTEMPTY
);

// DAC FIFO
fifo #(.DWIDTH(32),.AWIDTH(3)) dac_fifo
(
    .rst    (rst),
    .clk    (clk),
    .write  (dac_fifo_write),
    .read   (dac_fifo_read),
    .din    (dac_fifo_write_data),
    .dout   (dac_fifo_read_data),
    .full   (dac_fifo_full),
    // verilator lint_off PINCONNECTEMPTY
    .empty  ()
    // verilator lint_on PINCONNECTEMPTY
);


// ADC FIFO
fwft_fifo #(.DWIDTH(32),.AWIDTH(3)) adc_fifo
(
    .rst    (rst),
    .clk    (clk),
    .write  (adc_fifo_write),
    .read   (adc_fifo_read),
    .din    (adc_fifo_write_data),
    .dout   (adc_fifo_read_data),
    // verilator lint_off PINCONNECTEMPTY
    .full   (),
    // verilator lint_on PINCONNECTEMPTY
    .empty  (adc_fifo_empty)
);


// Audio Codec transceiver
audio_codec_transceiver #(.SYSCLK(SYSCLK*1000))
audio_codec_transceiver
(
    .clk            (clk),
    .rst            (rst),
    .dacdat_in      (dacdat_in),
    .dacdat_req     (dacdat_req),
    .adcdat_out     (adcdat_out),
    .adcdat_vld     (adcdat_vld),
    .bclk           (bclk),
    .mclk           (mclk),
    .daclrc         (daclrc),
    .dacdat         (dacdat),
    .adclrc         (adclrc),
    .adcdat         (adcdat)
);

endmodule
