///////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 by Heqing Huang (feipenghhq@gamil.com)
//
// Project Name: N/A
// Module Name: avmm_vram_controller
//
// Author: Heqing Huang
// Date Created: 11/08/2020
//
// ================== Revision 2.0 ==================
//
// Video Ram Controller.
//
// This controller use IS61LV25616 SRAM as the VRAM
// It provides two Avalon Memory Mapped interface:
// 1. One read interface for the VRAM controller to read the VRAM.
// 2. One write interface for the graphic generator (GPU/CPU) to write the VRAM.
//
// The read interface and write interface takes turn to access the SRAM but the
// read interface has higher priority.
//
// The SRAM is organized to 512X8 bit.
//
// This is a fully pipelined controller, here is the pipeline diagram:
//
// |  op    | t1   | t2     | t3     | t4     |        |       |
// | ------ | ---- | ------ | ------ | ------ | ------ | ----- |
// | read0  | Log  | Access | Ready  |        |        |       |
// | read1  |      | Log    | Access | Ready  |        |       |
// | write0 |      |        | Log    | Access | Nop    |       |
// | read2  |      |        |        | Log    | Access | Ready |
//  Log: log the input request
//  Access: Access the memory (read or write)
//  Ready: Data available in this stage
//
//  Both read and write latency is 2.
//
///////////////////////////////////////////////////////////////////////////////

module avmm_vram_controller #(
parameter CPU_CREDIT  = 64,
parameter VRAM_CREDIT = 128
)(
    // clk and reset
    input                   clk,
    input                   rst,

    // Avalon MM slave interface - for GPU/CPU side
    input  [18:0]           avs_cpu_address,    // Support 512KByte Address Range,  byte address
    input                   avs_cpu_write,
    input  [7:0]            avs_cpu_writedata,
    output                  avs_cpu_waitrequest,

    // Avalon MM slave interface - for VRAM controller side
    output                  avs_vram_waitrequest,
    output [7:0]            avs_vram_readdata,
    output                  avs_vram_readdatavalid,
    input  [18:0]           avs_vram_address,
    input                   avs_vram_read,

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

    localparam CREDIT_WIDTH = (VRAM_CREDIT > CPU_CREDIT) ? $clog2(VRAM_CREDIT+1) : $clog2(CPU_CREDIT+1);

    // ==============================
    // Registers and wires
    // ==============================
    // log to Access stage
    reg                     s0_req;
    reg                     s0_read;
    reg                     s0_write;
    reg [18:0]              s0_address;
    reg [7:0]               s0_write_data;
    // Access to Ready/Nop stage
    reg                     s1_read;
    reg [7:0]               s1_read_data;

    wire [CREDIT_WIDTH-1:0] cpu_credit;
    wire [CREDIT_WIDTH-1:0] vram_credit;
    wire                    avs_cpu_write_grant;
    wire                    avs_vram_read_grant;
    wire                    avs_cpu_credit_avail;
    wire                    avs_vram_credit_avail;

    // ==============================
    // Log Stage
    // ==============================

    // Aribitration between the read and write
    // Aribitration Scheme:
    // A. If there is only 1 request, it get the grant.
    // B. If both cpu/vram asserts request:
    //   1. As long as vram has credit it get the grant.
    //   2. If vram has no credit then cpu get the grant
    //  Ideally when in waitrequest, the host should not assert request.
    //
    assign cpu_credit = CPU_CREDIT[CREDIT_WIDTH-1:0];
    assign vram_credit = VRAM_CREDIT[CREDIT_WIDTH-1:0];

    wrr_arbiter #(.WIDTH(2), .CREDIT_WIDTH(CREDIT_WIDTH))
    cpu_vram_arbiter(
        .clk            (clk),
        .rst            (rst),
        .credits        ({cpu_credit, vram_credit}),
        .req            ({avs_cpu_write, avs_vram_read}),
        .grant          ({avs_cpu_write_grant, avs_vram_read_grant}),
        /* verilator lint_off PINCONNECTEMPTY */
        .grant_flopped  (),
        /* verilator lint_on PINCONNECTEMPTY */
        .credit_avail   ({avs_cpu_credit_avail, avs_vram_credit_avail})
    );

    assign avs_vram_waitrequest = ~avs_vram_credit_avail;
    assign avs_cpu_waitrequest = ~avs_cpu_credit_avail | ( avs_vram_read & ~avs_vram_waitrequest);

    // Log to Access Pipeline
    always @(posedge clk) begin
        if (rst) s0_req <= 1'b0;
        else s0_req <= avs_vram_read_grant | avs_cpu_write_grant;
    end

    always @(posedge clk) begin
        s0_read <= avs_vram_read_grant;
        s0_write <= avs_cpu_write_grant;
        s0_address <= avs_vram_read ? avs_vram_address : avs_cpu_address;
        s0_write_data <= avs_cpu_writedata;
    end

    // ==============================
    // Access Stage
    // ==============================
    assign sram_addr = s0_address[18:1];
    assign sram_writedata = {s0_write_data, s0_write_data};
    assign sram_ce_n = ~s0_req;
    assign sram_oe_n = ~s0_read;
    assign sram_we_n = ~s0_write;
    assign sram_ub_n = ~s0_address[0];
    assign sram_lb_n = s0_address[0];

    always @(posedge clk) begin
        s1_read <= s0_read;
        s1_read_data <= s0_address[0] ? sram_readdata[15:8] : sram_readdata[7:0];
    end

    // ==============================
    // Ready Stage
    // ==============================
    assign avs_vram_readdatavalid = s1_read;
    assign avs_vram_readdata = s1_read_data;

endmodule
