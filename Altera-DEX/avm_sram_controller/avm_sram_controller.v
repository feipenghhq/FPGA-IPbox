///////////////////////////////////////////////////////////////////////////////
//
// Project Name: N/A
// Module Name: avm_sram_controller
//
// Author: Heqing Huang
// Date Created: 10/07/2020
//
// ================== Description ==================
//
//  Revision 1.0 - 10/07/2020:
//  Avalon Memory Mapped SRAM Controller for Altere DE2 Board
//  The SRAM used in Altera DE2 Board is IS61LV25616
//
//  This module Takes 1 clock cycle to read and 1 clock cycle to write
//  The read data is available at the next clock cycle
//
//  Regarding the Avalon MM Interface
//  1. The address width and data width for Avalon MM interface are
//  fixed to 18 and 16 respectively which matches with the SRAM.
//  2. No wait state support.
//
//  Regarding the SRAM
//  1. The maximum clock speed supported is 50Mhz which is limited by the SRAM
//  2. The actual data signals of the SRAM are bidirectional, which should be
//     handled at the top level.
//  3. The read and writa operation are asynchronous.
///////////////////////////////////////////////////////////////////////////////

module avm_sram_controller
(
    // clk and reset
    input                   clk,
    input                   reset,

    // Avalon MM slave interface
    input  [17:0]           avm_address,
    input  [1:0]            avm_byteenable,
    input                   avm_read,
    input                   avm_write,
    input  [15:0]           avm_writedata,
    output [15:0]           avm_readdata,

    // SRAM interface
    output [17:0]           sram_addr,
    output [15:0]           sram_writedata,
    output                  sram_ce_n,
    output                  sram_oe_n,
    output                  sram_we_n,
    output                  sram_ub_n,
    output                  sram_lb_n,
    input  [15:0]           sram_readdata
);

    // ******************************
    // Avalon MM slave interface
    // ******************************

    reg [17:0]              avm_address_s1;
    reg [1:0]               avm_byteenable_s1;
    reg                     avm_read_s1;
    reg                     avm_write_s1;
    reg [15:0]              avm_writedata_s1;

    always @(posedge clk)
    begin
        if (reset) begin
            avm_read_s1            <= 1'b0;
            avm_write_s1           <= 1'b0;
        end
        else begin
            avm_read_s1            <= avm_read;
            avm_write_s1           <= avm_write;
        end
    end

    always @(posedge clk)
    begin
        avm_address_s1     <= avm_address;
        avm_byteenable_s1  <= avm_byteenable;
        avm_writedata_s1   <= avm_writedata;
    end

    assign avm_readdata = sram_readdata;

    // ******************************
    // SRAM interface
    // ******************************

    assign sram_addr = avm_address_s1;
    assign sram_writedata = avm_writedata_s1;
    assign sram_ce_n = ~(avm_read_s1 | avm_write_s1);
    assign sram_oe_n = ~avm_read_s1;
    assign sram_we_n = ~avm_write_s1;
    assign sram_ub_n = ~avm_byteenable_s1[1];
    assign sram_lb_n = ~avm_byteenable_s1[0];

endmodule
