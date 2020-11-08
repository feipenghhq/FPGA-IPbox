///////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 by Heqing Huang (feipenghhq@gamil.com)
//
// Project Name:
// Module Name: async_fifo_tb
//
// Author: Heqing Huang
// Date Created: 11/07/2020
//
// ================== Description ==================
//
// Testbench for async FIFO
//
///////////////////////////////////////////////////////////////////////////////

`timescale 1ns/10ps

module fifo_tb ();

parameter DWIDTH = 32;
parameter DEPTH = 16;
parameter CLK_PROD = 10;

reg               rst = 0;
reg               clk;
reg               read = 0;
wire [DWIDTH-1:0] dout;
wire              empty;
reg [DWIDTH-1:0]  din = 0;
reg               write = 0;
wire              full;
// QUEUE model
reg                push = 0;
reg [DWIDTH-1:0]   push_data;
reg                pop = 0;
wire [DWIDTH-1:0]  pop_data;

integer            error = 0;
integer            data = 0;
integer            push_done = 0;
integer            pop_done = 0;

fifo #(.DEPTH(DEPTH)) DUT_fifo(.*);
queue queue(.*);

// ================================================
// Main task
// ================================================

// push side
initial
begin
    wait(rst == 0);
    #100;
    repeat (100) begin
        if (!full) fifo_push();
        else @(posedge clk);
    end
    push_done = 1;
end

// pop side
initial
begin
    wait(rst == 0);
    #1000;
    repeat (100) begin
        if (!empty) fifo_pop();
        else @(posedge clk);
    end
    pop_done = 1;
end

initial
begin
    wait(push_done && pop_done);
    print_result();
    $finish;
end

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
// Common task
// ================================================

task fifo_push;
begin
    @(negedge clk);
    //din = $random;
    din = data;
    push_data = din;
    data = data + 1;
    write = 1;
    push = 1;
    $display("[ASYNC FIFO ENV] Push data %h into FIFO at time %5t", din, $time);
    @(posedge clk);
    #1;
    write = 0;
    push = 0;
end
endtask

task fifo_pop;
begin
    @(negedge clk);
    read = 1;
    pop = 1;
    @(posedge clk);
    #1;
    read = 0;
    pop = 0;
    if (dout !== pop_data) begin
        $display("[ASYNC FIFO ENV] ERROR: Get wrong pop data from FIFO at time %5t. Expected %x, but get %x.",
                $time, pop_data, dout);
        error = error + 1;
    end
    else begin
        $display("[ASYNC FIFO ENV] Get correct pop data from FIFO %x at time %5t", dout, $time);
    end
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
    $dumpvars(0, fifo_tb);
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
