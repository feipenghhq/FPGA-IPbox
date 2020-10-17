///////////////////////////////////////////////////////////////////////////////
//
// Project Name: N/A
// Module Name: avm_sram_controller_tb
//
// Author: Heqing Huang
// Date Created: 10/10/2020
//
//  ================== Revision 1.0 ==================
//  Testbench for the avm_sram_controller
//
///////////////////////////////////////////////////////////////////////////////

`timescale 1ns/10ps

`define PERIOD 25

module avm_sram_controller_tb();

    // clk and reset
    reg                 clk;
    reg                 reset;

    // Avalon MM slave interface
    reg  [18:0]         avm_address;
    reg  [3:0]          avm_byteenable;
    reg                 avm_read;
    reg                 avm_write;
    reg  [31:0]         avm_writedata;
    wire [31:0]         avm_readdata;

    // SRAM interface
    wire [17:0]         sram_addr;
    wire [15:0]         sram_writedata;
    wire                sram_ce_n;
    wire                sram_oe_n;
    wire                sram_we_n;
    wire                sram_ub_n;
    wire                sram_lb_n;
    wire  [15:0]        sram_readdata;

    reg                 error;

    initial
    begin
        error = 0;
        avm_address = 0;
        avm_byteenable = 0;
        avm_read = 0;
        avm_write = 0;
        avm_writedata = 0;
        clk = 0;
        reset = 1;
    end

    always @(*) #(`PERIOD/2) clk <= ~clk;

    initial
    begin
        repeat (5) @(posedge clk);
        #1 reset = 0;
        @(posedge clk);
        // write data into sram
        avm_write_op('h0, 4'b1111, 'hcccc0123, 0);
        avm_write_op('h4, 4'b1111, 'hbbbbaaaa, 0);
        avm_read_op('h4, 4'b1111, 'hbbbbaaaa);
        avm_write_op('h8, 4'b1111, 'h12344567, 0);
        avm_write_op('hc, 4'b1111, 'h0000abcd, 0);
        avm_write_op('h20, 4'b1111, 'hdeadbeef, 0);
        avm_read_op('h0, 4'b1111, 'hcccc0123);
        avm_read_op('h8, 4'b1111, 'h12344567);
        avm_read_op('h20, 4'b1111, 'hdeadbeef);
        avm_read_op('hc, 4'b1111, 'h0000abcd);
        avm_read_op('h4, 4'b1111, 'hbbbbaaaa);
        avm_write_op('h20, 4'b0011, 'h0000ffff, 0);
        avm_read_op('h20, 4'b1111, 'hdeadffff);
        avm_write_op('h10, 4'b1111, 'h12345678, 0);
        avm_write_op('h10, 4'b1000, 'hff345678, 0);
        avm_read_op('h10, 4'b0011, 'hff345678);
        repeat (5) @(posedge clk);
        print_result();
        $finish();
    end

    avm_sram_controller DUT(.*);

    sram_model sram_model(.*);

    initial
    begin
        $dumpfile("dump.vcd");
        $dumpvars(0, avm_sram_controller_tb);
        //for (integer idx = 0; idx < 40; idx = idx + 1) begin
        //    $dumpvars(0, avm_sram_controller_tb.sram_model.sram[idx]);
        //end
    end

    task avm_write_op;
        input [18:0] addr;
        input [3:0]  byte;
        input [31:0] data;
        input [31:0] expected;
        begin
            $display("Avalon MM write access. Address: %d, Data %h", addr, data);
            #1;
            avm_address = addr;
            avm_byteenable = byte;
            avm_read = 0;
            avm_write = 1;
            avm_writedata = data;
            @(posedge clk);
            #1;
            avm_address = 0;
            avm_byteenable = 0;
            avm_read = 0;
            avm_write = 0;
            avm_writedata = 0;
            repeat (2) @(posedge clk);
        end
    endtask

    task avm_read_op;
        input [18:0] addr;
        input [3:0]  byte;
        input [31:0] expected;
        begin
            //$display("Avalon MM read access.  Address: %d", addr);
            #1;
            avm_address = addr;
            avm_byteenable = byte;
            avm_read = 1;
            avm_write = 0;
            @(posedge clk);
            #1;
            avm_address = 0;
            avm_byteenable = 0;
            avm_read = 0;
            avm_write = 0;
            repeat (2) @(posedge clk);
            #1;
            if (expected !== avm_readdata) begin
                $display("ERROR: Read data mismatch. Address: %d, Expected Data %h, Actual Data %h",
                          addr, expected, avm_readdata);
                error = 1;
            end
            else begin
                $display("Read data matches.      Address: %d, Expected Data %h, Actual Data %h",
                          addr, expected, avm_readdata);
            end
        end
    endtask


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


// To save space, the SRAM model here only models address range of 0 ~ 127 which is 7 bit wide address
module sram_model (
    input [17:0]       sram_addr,
    input [15:0]       sram_writedata,
    input              sram_ce_n,
    input              sram_oe_n,
    input              sram_we_n,
    input              sram_ub_n,
    input              sram_lb_n,
    output reg [15:0]  sram_readdata
);

    reg  [15:0]         sram[127:0];

    always @(*) begin
        if (!sram_ce_n && !sram_we_n) begin
            #1;
            if (!sram_ub_n) sram[sram_addr][15:8] <= sram_writedata[15:8];
            if (!sram_lb_n) sram[sram_addr][7:0]  <= sram_writedata[7:0];
        end

        if (!sram_ce_n && !sram_oe_n && sram_we_n) begin
            #1;
            sram_readdata <= sram[sram_addr];
        end
    end

endmodule
