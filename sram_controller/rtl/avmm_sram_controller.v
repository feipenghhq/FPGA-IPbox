///////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 by Heqing Huang (feipenghhq@gamil.com)
//
// Project Name: N/A
// Module Name: avs_sram_controller
//
// Author: Heqing Huang
// Date Created: 10/10/2020
//
// ================== Revision 2.0 ==================
//
//  Revision 2.0 - 10/10/2020:
//
//  This version support 32 bit data width. It has register at both input and output
//  to improve timing but introducing 1 extra latency.
//
//  Max clock speed supported 50Mhz (limited by the SRAM)
//
//  **** Important ****
//
//  1. The avs_address input should be a byte address, not a word address.
//     So when you create a QSYS component of this IP, the address unit should be "SYMBOL"
//     And the bit per symbol is 8.
//     This is very important for this IP to work
//
//  2. Latency:
//      Read  latency: 3
//      Write latency: 3
//
//
//  ================== Revision 1.0 ==================
//
//  Revision 1.0 - 10/07/2020:
//  Avalon Memory Mapped SRAM Controller for Altere DE2 Board
//  The SRAM used in Altera DE2 Board is IS61LV25616
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
//
///////////////////////////////////////////////////////////////////////////////

module avmm_sram_controller
(
    // clk and reset
    input                   clk,
    input                   reset,

    // Avalon MM slave interface
    input      [18:0]       avs_address,    // Support 512KByte Address Range,  byte address
    input      [3:0]        avs_byteenable,
    input                   avs_read,
    input                   avs_write,
    input      [31:0]       avs_writedata,
    output reg [31:0]       avs_readdata,

    // SRAM interface
    output reg [17:0]       sram_addr,
    output reg [15:0]       sram_writedata,
    output reg              sram_ce_n,
    output reg              sram_oe_n,
    output reg              sram_we_n,
    output reg              sram_ub_n,
    output reg              sram_lb_n,
    input  [15:0]           sram_readdata
);

    // ******************************
    // State Machine
    // ******************************

    localparam S_IDLE       = 0;    // Idle state
    localparam S_DW0        = 1;    // Captured the input request, send out DW0 request to SRAM
    localparam S_DW1        = 2;    // Captured DW0, send out DW1 request to SRAM

    reg [2:0]               state;

    // state machine
    always @(posedge clk)
    begin
        if (reset) begin
            state <= S_IDLE;
        end
        else begin
            case(state)
                S_IDLE:     state <= (avs_read || avs_write) ? S_DW0 : S_IDLE;
                S_DW0:      state <= S_DW1;
                S_DW1:      state <= S_IDLE;
                default:    state <= S_IDLE;
            endcase
        end
    end

    // ******************************
    // Avalon MM slave interface
    // ******************************

    reg [17:0]              avs_address_dw1;
    reg [1:0]               avs_byteenable_dw1;
    reg [15:0]              avs_writedata_dw1;

    always @(posedge clk)
    begin
        case(state)
            S_IDLE:begin // Idle state, capture the input
                avs_writedata_dw1   <= avs_writedata[31:16];
                avs_byteenable_dw1  <= avs_byteenable[3:2];
                // the SRAM is arranged as 256K x 16b so the LSb from avs_address is not used
                avs_address_dw1     <= avs_address[18:1] | 17'h1;
            end
            S_DW0:begin // DW1 is availabe at the end of S_CAPTURE state
                avs_readdata[15:0]  <= sram_readdata;
            end
            S_DW1:begin // DW1 is availabe at the end of S_CAPTURE state
                avs_readdata[31:16] <= sram_readdata;
            end
        endcase
    end


    // ******************************
    // SRAM interface
    // ******************************
    always @(posedge clk)
    begin
        if (reset) begin
            sram_ce_n <= 1'b1;
            sram_oe_n <= 1'b1;
            sram_we_n <= 1'b1;
            sram_ub_n <= 1'b1;
            sram_lb_n <= 1'b1;
        end
        else begin
            case(state)
                S_IDLE:begin // Idle state, capture the input
                    sram_ce_n   <= ~(avs_read | avs_write);
                    sram_oe_n   <= ~avs_read;
                    sram_we_n   <= ~avs_write;
                    sram_ub_n   <= ~avs_byteenable[1];
                    sram_lb_n   <= ~avs_byteenable[0];
                    sram_writedata  <= avs_writedata[15:0];
                    // Note: the SRAM is arranged as 256K x 16b so the LSb from avs_address is not used
                    sram_addr   <= avs_address[18:1];
                end
                S_DW0:begin
                    sram_ub_n   <= ~avs_byteenable_dw1[1];
                    sram_lb_n   <= ~avs_byteenable_dw1[0];
                    sram_addr   <= avs_address_dw1;
                    sram_writedata  <= avs_writedata_dw1;
                end
                S_DW1:begin
                    sram_ce_n <= 1'b1;
                    sram_oe_n <= 1'b1;
                    sram_we_n <= 1'b1;
                    sram_ub_n <= 1'b1;
                    sram_lb_n <= 1'b1;
                end
            endcase
        end
    end

endmodule
