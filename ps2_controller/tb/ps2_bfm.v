///////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 by Heqing Huang (feipenghhq@gamil.com)
//
// Project Name: PS2 Controller
// Module Name: ps2_bfm
//
// Author: Heqing Huang
// Date Created: 10/31/2020
//
// ================== Description ==================
//
//  PS2 Bus Function Model
//
///////////////////////////////////////////////////////////////////////////////

module ps2_bfm(
// PS2 interface
inout               ps2_data,
inout               ps2_clk,
output reg [7:0]    golden_tx_data,
input               insert_err,
input               send_data
);

parameter CLK_PROD = 20;
parameter PS2_PROD = CLK_PROD * 1000;   // not the exact scaled timing

reg [7:0]           tx_data;
reg [7:0]           tx_data_copy;
reg                 ps2_clk_o = 1;
reg                 ps2_clk_w = 1;
wire                ps2_clk_i;
reg                 ps2_data_o = 1;
reg                 ps2_data_w = 1;
wire                ps2_data_i;
reg                 tx_parity_bit;
reg                 start_tx_clk = 0;
integer             tx_i;
integer             tx_clk_i;


assign ps2_clk = ps2_clk_w ? ps2_clk_o : 1'bz;
assign ps2_clk_i = ps2_clk;
assign ps2_data = ps2_data_w ? ps2_data_o : 1'bz;
assign ps2_data_i = ps2_data;

// ================================================
// TX path
// ================================================
always@(*) begin
    // wait for the condition to start.
    wait(send_data);    // wait for env to ask for new data
    wait(ps2_clk_i && ps2_data_i);  // wait for idle state
    // start condition
    ps2_data_o = 1'b0;
    ps2_data_w = 1'b1;
    // start the clock
    start_tx_clk = 1'b1;   // start to generate the clock for tx
    tx_i = 0;
    tx_data = $random;
    tx_data_copy = tx_data;
    tx_parity_bit = ^tx_data ^ 1'b1; // old parity
    $display("[PS2 BFM] Start sending data %h at time %t", tx_data, $time);
    while (tx_i < 8) begin
        @(posedge ps2_clk);
        ps2_data_o = tx_data;
        tx_data = tx_data >> 1;
        tx_i = tx_i + 1'b1;
    end
    golden_tx_data = tx_data_copy;
    // parity bit
    @(posedge ps2_clk);
    ps2_data_o = tx_parity_bit ^ insert_err;
    // stop condition
    @(posedge ps2_clk);
    ps2_data_o = 1;
    // release the bus
    @(posedge ps2_clk);
    ps2_data_o = 1'b1;
    ps2_data_w = 1'b0;
    start_tx_clk = 1'b0;
    #(CLK_PROD * 2);    // wait 2 sys clock period before next xfer
    $display("[PS2 BFM] Finish sending data %h at time %t", golden_tx_data, $time);
end

// ================================================
// TX Clock generation
// ================================================
always @(*) begin
    wait(start_tx_clk);
    tx_clk_i = 0;
    ps2_clk_w = 1'b1;
    // Generate clock for 11 bits
    while (tx_clk_i < 11) begin
        #(PS2_PROD/2);
        ps2_clk_o = 1'b0;
        #(PS2_PROD/2);
        ps2_clk_o = 1'b1;
        tx_clk_i = tx_clk_i + 1;
    end
    ps2_clk_o = 1'b1;
    ps2_clk_w = 1'b0;
end

endmodule