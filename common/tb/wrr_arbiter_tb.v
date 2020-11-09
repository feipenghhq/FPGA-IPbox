///////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 by Heqing Huang (feipenghhq@gamil.com)
//
// Project Name: N/A
// Module Name: wrr_arbiter_tb
//
// Author: Heqing Huang
// Date Created: 11/08/2020
//
// ================== Description ==================
//
//  Testbench for Weighted Round Robin Arbiter.
//
///////////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

module wrr_arbiter_tb ();
parameter WIDTH         = 2;
parameter CRD_WIDTH     = 4;
parameter TOTAL_WIDTH   = CRD_WIDTH * WIDTH;
parameter CLK_PROD      = 20;

reg                       clk;
reg                       rst = 1;
reg  [TOTAL_WIDTH-1:0]    credits;
reg  [TOTAL_WIDTH-1:0]    expected_credits;
reg  [WIDTH-1:0]          req;
wire [WIDTH-1:0]          grant_flopped;
wire [WIDTH-1:0]          grant;
wire [WIDTH-1:0]          credit_avail;

integer                   error = 0;

wrr_arbiter #(.WIDTH(WIDTH), .CRD_WIDTH(CRD_WIDTH)) dut_wrr_arbiter(.*);

initial begin
    // initialize credit
    credits = {4'd4, 4'd4};
    wait(rst == 0);
    gen_req(2'b00, 2'b00, 2'b11);
    gen_req(2'b01, 2'b01, 2'b11);
    gen_req(2'b10, 2'b10, 2'b11);
    gen_req(2'b11, 2'b01, 2'b11);
    gen_req(2'b11, 2'b01, 2'b11);
    gen_req(2'b11, 2'b01, 2'b11);
    gen_req(2'b11, 2'b10, 2'b10);
    gen_req(2'b11, 2'b10, 2'b10);
    gen_req(2'b11, 2'b10, 2'b10);
    gen_req(2'b00, 2'b00, 2'b11);
    #100;
    $finish;
end

task gen_req;
    input [WIDTH-1:0] req_i;
    input [WIDTH-1:0] expected_grant;
    input [WIDTH-1:0] expected_credit_avail;
    begin
        @(negedge clk);
        #1;
        req = req_i;
        #1;
        // test result as it comes at the same clock cycle
        if (grant != expected_grant) begin
            error = error + 1;
            $display("[WRR ARBITER ENV] ERROR: Get wrong grant signal at time %5t. Expected %b, Get %b.", $time, expected_grant, grant);
        end
        else begin
            $display("[WRR ARBITER ENV] Get correct grant signal at time %5t. Request %b, Grant %b.", $time, req, grant);
        end
        @(posedge clk);
        #1;
        req = 'b0;

    end
endtask


// ================================================
// Reset
// ================================================

initial
begin
    rst = 1'b1;
    #100;
    @(posedge clk);
    #1 rst = 1'b0;
end

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
    $dumpvars(0, wrr_arbiter_tb);
end

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