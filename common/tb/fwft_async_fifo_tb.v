///////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 by Heqing Huang (feipenghhq@gamil.com)
//
// Project Name:
// Module Name: fwft_async_fifo
//
// Author: Heqing Huang
// Date Created: 11/07/2020
//
// ================== Description ==================
//
// Testbench for async FIFO
//
///////////////////////////////////////////////////////////////////////////////


module fwft_async_fifo_tb ();

parameter DWIDTH = 32;
parameter DEPTH = 16;
parameter AMOST_FULL = 4;
parameter AMOST_EMPTY = 4;

parameter CLK_WR_PROD = 10;
parameter CLK_RD_PROD = 20;

// Read side
reg               rst_rd = 0;
reg               clk_rd;
reg               read = 0;
wire [DWIDTH-1:0] dout;
wire              empty;
wire              almost_empty;
// Write side
reg               rst_wr = 0;
reg               clk_wr;
reg [DWIDTH-1:0]  din = 0;
reg               write = 0;
wire              full;
wire              almost_full;
// QUEUE model
reg                push = 0;
reg [DWIDTH-1:0]   push_data;
reg                pop = 0;
wire [DWIDTH-1:0]  pop_data;

integer            error = 0;
integer            data = 0;
integer            push_done = 0;
integer            pop_done = 0;

fwft_async_fifo DUT_fwft_async_fifo(.*);
queue queue(.*);

// ================================================
// Main task
// ================================================

// push side
initial
begin
    wait(rst_rd == 0 && rst_wr == 0);
    #100;
    repeat (100) begin
        if (!full) fifo_push();
        else @(posedge clk_wr);
    end
    push_done = 1;
end

// pop side
initial
begin
    wait(rst_rd == 0 && rst_wr == 0);
    #100;
    repeat (100) begin
        if (!empty) fifo_pop();
        else @(posedge clk_rd);
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
    rst_wr = 1'b1;
    #100;
    @(posedge clk_wr);
    #1 rst_wr = 1'b0;
end

initial
begin
    rst_rd = 1'b1;
    #100;
    @(posedge clk_rd);
    #1 rst_rd = 1'b0;
end


// ================================================
// Common task
// ================================================

task fifo_push;
begin
    @(negedge clk_wr);
    //din = $random;
    din = data;
    push_data = din;
    data = data + 1;
    write = 1;
    push = 1;
    $display("[ASYNC FIFO ENV] Push data %h into FIFO at time %5t", din, $time);
    @(posedge clk_wr);
    #1;
    write = 0;
    push = 0;
end
endtask

task fifo_pop;
begin
    @(negedge clk_rd);
    pop = 1;    // pop the queue model first
    #1;
    // check the data before read as we are FWFT
    if (dout !== pop_data) begin
        $display("[ASYNC FIFO ENV] ERROR: Get wrong pop data from FIFO at time %5t. Expected %x, but get %x.",
                $time, pop_data, dout);
        error = error + 1;
    end
    else begin
        //$display("[ASYNC FIFO ENV] Get correct pop data from FIFO %x at time %5t", dout, $time);
        $display("[ASYNC FIFO ENV] Get correct pop data from FIFO at time %5t. Expected %x, Get %x.",
                $time, pop_data, dout);
    end
    read = 1;
    @(posedge clk_rd);
    #1;
    read = 0;
    pop = 0;
end
endtask

// ================================================
// clock
// ================================================
initial
begin
    clk_wr = 1;
    forever begin
        #(CLK_WR_PROD/2) clk_wr = ~clk_wr;
    end
end

initial
begin
    clk_rd = 1;
    forever begin
        #(CLK_RD_PROD/2) clk_rd = ~clk_rd;
    end
end

// ================================================
// Dump test
// ================================================
initial
begin
    $dumpfile("dump.vcd");
    $dumpvars(0, fwft_async_fifo_tb);
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
