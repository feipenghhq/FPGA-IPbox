///////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 by Heqing Huang (feipenghhq@gamil.com)
//
// Project Name: PS2 Controller
// Module Name: ps2_rx_tb
//
// Author: Heqing Huang
// Date Created: 10/31/2020
//
// ================== Description ==================
//
//  PS2 TX testbench
//
///////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ns

module ps2_tx_tb();

// DUT
reg               clk;
reg               rst;

// PS2 interface
wire              ps2_data_i;
wire              ps2_data_o;
wire              ps2_data_w;
wire              ps2_clk_i;
wire              ps2_clk_w;
wire              ps2_clk_o;

// Host interface
reg               rx_busy = 0;    // RX path is busy
reg               send_req = 0;
reg [7:0]         send_data = 0;
wire              send_idle;


// BFM
tri               ps2_data;
tri               ps2_clk;
reg               receive_data_bfm = 0;
wire [7:0]        golden_tx_data;
wire [7:0]        received_data;
wire              send_data_bfm = 0;
reg               insert_err = 0; 
integer           error = 0;

parameter CLK_PROD = 20;
parameter DELTA = 1;

// ================================================
// DUT and BFM
// ================================================
ps2_tx ps2_tx(.*);
ps2_bfm ps2_bfm(.*);

pullup(ps2_data);
pullup(ps2_clk);

assign ps2_clk = ps2_clk_w ? ps2_clk_o : 1'bz;
assign ps2_data = ps2_data_w ? ps2_data_o : 1'bz;
assign ps2_data_i = ps2_data;
assign ps2_clk_i = ps2_clk;

// ================================================
// Test
// ================================================
initial begin
    // reset
    rst = 1'b1;
    #100;
    @(posedge clk);
    #1 rst = 1'b0;
    @(posedge clk);
    // reset released
    env_send_new_data($random, 0);
    env_send_new_data($random, 0);
    env_send_new_data($random, 1);
    print_result();
    $finish;
end



// ================================================
// Task
// ================================================
parameter HOLD_TIME = 100;

task env_send_new_data;
    input [7:0] send_data_i;
    input rx_busy_i;
begin

    // wait for optional rx busy time
    receive_data_bfm = 1'b1;
    rx_busy = 1'b1;
    if (rx_busy_i) begin
        #HOLD_TIME;
    end
    $display("[env_send_new_data]: Sending new data %x at time %t", send_data_i, $time);
    @(posedge clk);
    #1;
    rx_busy = 1'b0;
    send_req = 1'b1;
    send_data = send_data_i;

    @(posedge clk);
    #1;
    send_req = 1'b0; 
    wait(send_idle);
    // check result
    if (send_data != received_data) begin
        $display("[PS2 RX] ERROR: BFM received wrong data. PS2 sent: %h, BFM received: %h at time %t",
                send_data, received_data, $time);
        error = error + 1;
    end
    else begin
        $display("[PS2 RX] Received correct data from BFM: %h", received_data);
    end
    receive_data_bfm = 1'b0;
    @(posedge clk);

end
endtask

// ================================================
// clock
// ================================================
initial
begin
    clk = 1;
    forever begin
        #(CLK_PROD/2) clk = ~clk;
    end
end

// ================================================
// Dump test
// ================================================
initial
begin
    $dumpfile("dump.vcd");
    $dumpvars(0, ps2_tx_tb);
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