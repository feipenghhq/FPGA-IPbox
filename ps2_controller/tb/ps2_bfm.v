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
output reg [7:0]    received_data,
input               receive_data_bfm,
input               insert_err,
input               send_data_bfm
);

parameter CLK_PROD = 20;
parameter PS2_PROD = CLK_PROD * 1000;   // not the exact scaled timing

reg [7:0]           tx_data;
reg [7:0]           tx_data_copy;
reg                 ps2_clk_o = 1;
reg                 ps2_clk_w = 0;
wire                ps2_clk_i;
reg                 ps2_data_o = 1;
reg                 ps2_data_w = 0;
wire                ps2_data_i;
reg                 rx_parity;
reg                 tx_parity_bit;
reg                 start_tx_clk = 0;
reg                 start_rx_clk = 0;
integer             tx_i;
integer             rx_i;
integer             tx_clk_i;
integer             num_clk;


assign ps2_clk = ps2_clk_w ? ps2_clk_o : 1'bz;
assign ps2_clk_i = ps2_clk;
assign ps2_data = ps2_data_w ? ps2_data_o : 1'bz;
assign ps2_data_i = ps2_data;

// ================================================
// TX path
// ================================================
always@(*) begin
    // wait for the condition to start.
    wait(send_data_bfm);    // wait for env to ask for new data
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
// RX path
// ================================================
always@(*) begin
    // wait for the condition to start.
    wait(receive_data_bfm);    // wait for env to ask receive data      
    wait(ps2_clk_i && ps2_data_i);  // wait for idle state  
    wait(!ps2_clk);     // wait for the clock going low
    #100000;            // wait for 100 us
    // start the clock
    start_rx_clk = 1'b1;   // start to generate the clock for rx
    @(negedge ps2_clk_i);
    $display("[PS2 BFM] Start receiving data at time %t", $time);
    rx_i = 0;
    rx_parity = 0;
    received_data = 0;
    while (rx_i < 8) begin
        @(posedge ps2_clk);
        received_data = {ps2_data_i, received_data[7:1]};
        rx_i = rx_i + 1'b1;
    end
    // parity bit
    @(posedge ps2_clk);
    rx_parity = (^received_data) ^ rx_parity;
    if (rx_parity) begin
        $display("[PS2 BFM] Received data has parity error.");
    end
    // stop condition
    @(posedge ps2_clk);
    // ACK condidion
    @(posedge ps2_clk);    
    ps2_data_o = 1'b0;
    ps2_data_w = 1'b1;    
    // release the bus
    @(posedge ps2_clk);
    ps2_data_o = 1'b1;
    ps2_data_w = 1'b0;
    start_rx_clk = 1'b0;
    $display("[PS2 BFM] Received data %x at time %t", received_data, $time);    
end

// ================================================
// Clock generation
// ================================================
always @(*) begin
    wait(start_tx_clk || start_rx_clk);
    tx_clk_i = 0;
    ps2_clk_w = 1'b1;
    if (start_tx_clk) num_clk = 11;
    if (start_rx_clk) num_clk = 12;
    // Generate clock for 11 bits
    while (tx_clk_i < num_clk) begin
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