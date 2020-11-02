///////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 by Heqing Huang (feipenghhq@gamil.com)
//
// Project Name: PS2 Controller
// Module Name: ps2_controller
//
// Author: Heqing Huang
// Date Created: 10/31/2020
//
// ================== Description ==================
//
// Avalon Memory Mapped PS2 Controller
//
///////////////////////////////////////////////////////////////////////////////

module avm_ps2_controller #(
parameter SYSCLK = 50       // System clock rate in MHz
) (

// clock and reset
input           clk,
input           rst,

// Avalon MM slave interface
input  [2:0]    avm_address,
input           avm_select,
input           avm_read,
input           avm_write,
input  [31:0]   avm_writedata,
output [31:0]   avm_readdata,

// PS2 interface
input           ps2_data_i,
output          ps2_data_w,
output          ps2_data_o,
input           ps2_clk_i,
output          ps2_clk_w,
output          ps2_clk_o,

// interrupt port
output          ps2_data_avail
);

ps2_controller #(.SYSCLK(SYSCLK)) ps2_controller
(
    .clk            (clk),
    .rst            (rst),
    .sw_address     (avm_address),
    .sw_read        (avm_read),
    .sw_write       (avm_write),
    .sw_select      (avm_select),
    .sw_wrdata      (avm_writedata),
    .sw_rddata      (avm_readdata),
    .ps2_data_i     (ps2_data_i),
    .ps2_data_w     (ps2_data_w),
    .ps2_data_o     (ps2_data_o),
    .ps2_clk_i      (ps2_clk_i),
    .ps2_clk_w      (ps2_clk_w),
    .ps2_clk_o      (ps2_clk_o),
    .ps2_data_avail (ps2_data_avail)
);

endmodule
