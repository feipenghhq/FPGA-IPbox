///////////////////////////////////////////////////////////////////////////////
//
// Project Name: Arty A7
// Module Name: Arty_TOP
//
// Author: Heqing Huang
// Date Created: 05/06/2019
//
// ================== Description ==================
//
//  Arty A7 FPGA board top level template.
//
///////////////////////////////////////////////////////////////////////////////

module Arty_TOP (

// clock and reset
input  CLK,         // PIN E3
input  CK_RST,      // PIN C2 (Pressed low)

// 4 LEDs
output LD4,         // PIN H5
output LD5,         // PIN J5
output LD6,         // PIN T9
output LD7,         // PIN T10

// 4 Switches
input  SW0,         // PIN A8
input  SW1,         // PIN C11
input  SW2,         // PIN C10
input  SW3,         // PIN A10

// 4 Buttons
input  BTN0,        // PIN D9
input  BTN1,        // PIN C9
input  BTN2,        // PIN B9
input  BTN3,        // PIN B8

// Uart
input  UART_RX,     // PIN A9
output UART_TX      // PIN D10

);





endmodule
