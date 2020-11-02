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
//  PS2 RX testbench
//
///////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ns

module ps2_rx_tb();

// DUT
reg               clk;
reg               rst;
wire              ps2_data_i;
wire              ps2_clk_i;
wire              ps2_clk_w;
wire              ps2_clk_o;
reg               hold_req;
reg               rx_en;
wire [7:0]        rcv_data;
wire              rcv_parity_err;
wire              rcv_no_stop_err;
wire              rcv_vld;
wire              rcv_idle;

// BFM
tri               ps2_data;
tri               ps2_clk;
wire [7:0]        golden_tx_data;
reg               send_data;
reg               insert_err;
integer           error = 0;

parameter CLK_PROD = 20;
parameter DELTA = 1;

// ================================================
// DUT and BFM
// ================================================
ps2_rx ps2_rx(.*);
ps2_bfm ps2_bfm(.*);

pullup(ps2_data);
pullup(ps2_clk);

assign ps2_clk = ps2_clk_w ? ps2_clk_o : 1'bz;
assign ps2_data_i = ps2_data;
assign ps2_clk_i = ps2_clk;

// ================================================
// Test
// ================================================
initial begin
    // initial value
    hold_req = 1'b0;
    rx_en = 1'b1;
    insert_err = 1'b0;
    send_data = 1'b0;
    // reset
    rst = 1'b1;
    #100;
    @(posedge clk);
    #1 rst = 1'b0;
    @(posedge clk);
    // reset released
    env_req_new_data(0, 0);
    env_req_new_data(1, 0);
    env_req_new_data(0, 1);
    print_result();
    $finish;
end



// ================================================
// Task
// ================================================
parameter HOLD_TIME = 100;

task env_req_new_data;
    input insert_err_i;
    input hold_req_i;
begin

    // wait for optional hold time
    wait(rcv_idle);
    if (hold_req_i) begin
        hold_req = 1'b1;
        #HOLD_TIME;
    end
    $display("[env_req_new_data]: New request at time %t", $time);
    // start the request to BFM and wait for the xfer completes
    @(posedge clk);
    #DELTA;
    hold_req = 1'b0;
    insert_err = insert_err_i;
    send_data = 1'b1;
    wait (rcv_vld);
    #DELTA;
    send_data = 1'b0;
    // check result
    if (rcv_data != golden_tx_data) begin
        $display("[PS2 RX] ERROR: Received wrong data. BFM sent: %h, PS2 received: %h at time %t",
                golden_tx_data, rcv_data, $time);
        error = error + 1;
    end
    else begin
        $display("[PS2 RX] Received correct data from BFM: %h", rcv_data);
    end
    if (insert_err_i && !rcv_parity_err) begin
        $display("[PS2 RX] ERROR: BFM inserted error but PS2 RX did not report error");
        error = error + 1;
    end
    else begin
        $display("[PS2 RX] BFM inserted error and PS2 reporter parity error");
    end

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
    $dumpvars(0, ps2_rx_tb);
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