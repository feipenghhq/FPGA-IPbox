///////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 by Heqing Huang (feipenghhq@gamil.com)
//
// Project Name: spi
// Module Name: spi_master_tb
//
// Author: Heqing Huang
// Date Created: 11/12/2020
//
// ================== Description ==================
//
// Testbenches for spi_master
//
///////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ns

module spi_master_tb();

parameter DWIDTH = 8;    // data width
parameter CLK_RPED = 10;

reg               clk = 0;
reg               rst = 0;

// User data interface
reg               send = 0;
reg [DWIDTH-1:0]  din = 0;
wire [DWIDTH-1:0] dout;
wire              rvld;

// config and status
reg               cpol = 0;   // polarity of the clock
reg               cpha = 1;   // polarity of the data
wire              idle;

// SPI signal
wire              sclk;   // SPI serial clock
wire              mosi;   // Master Out Slave in
wire              miso;   // Master in Slave out
wire              cs;     // Chip select


wire [DWIDTH-1:0] received_data;
wire [DWIDTH-1:0] send_data;

integer           error = 0;

spi_master dut_spi_master (.*);
spi_slave_bfm spi_slave_bfm (.*);

initial
begin
    rst = 1'b1;
    #100;
    @(posedge clk);
    rst = 1'b0;
    new_req();
    #100;
    print_result();
    $finish;
end


task new_req;
begin
    @(posedge clk);
    #1 send = 1'b1;
    din = $random;
    @(posedge clk);
    #1 send = 1'b0;
    wait(rvld);
    if (received_data !== din) begin
        $display("[SPI MASTER ENV]: BFM get wrong data. Send %x, BFM gets %x.     time: %t",
                din, received_data, $time);
        error = error + 1;
    end
    else begin
        $display("[SPI MASTER ENV]: BFM get correct data. Send %x, BFM gets %x.     time: %t",
                din, received_data, $time);
    end
    if (send_data !== dout) begin
        $display("[SPI MASTER ENV]: SPI get wrong data. BFM Send %x, SPI gets %x. time: %t",
                send_data, dout, $time);
        error = error + 1;
    end
    else begin
        $display("[SPI MASTER ENV]: SPI get correct data. BFM Send %x, SPI gets %x. time: %t",
                send_data, dout, $time);
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


// ================================================
// clock
// ================================================
initial
begin
    clk = 1;
    forever begin
        #(CLK_RPED/2) clk = ~clk;
    end
end

// ================================================
// Dump test
// ================================================
initial
begin
    $dumpfile("dump.vcd");
    $dumpvars(0, spi_master_tb);
end

endmodule