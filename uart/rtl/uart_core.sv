///////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 by Heqing Huang (feipenghhq@gamil.com)
//
// Project Name: Uart
// Module Name: uart_core
//
// Author: Heqing Huang
// Date Created: 05/06/2019
//
// ================== Description ==================
//
//  Revision 1.0:
//   uart core logic containing both uart_tx and uart_rx
//   1. buadrate and clock frequency are controlled by parameters.
//   2. This design support fixed 8 bit.
//   3. configurable parity: Support no parity, even parity, odd parity
//      cfg_parity bit 0: 0 no parity, 1 has parity.
//      cfg_parity bit 1: 0 even parity, 1 odd parity
//   4. configurable number of stop bit. Support 1, 1.5, 2 bits
//      cfg_stop_bits: 0 - 1 bit; 1 - 1.5 bit; 2 - 2 bit
//
///////////////////////////////////////////////////////////////////////////////

module uart_core #(
parameter BUADRATE = 115200,      // buadrate
parameter CLKFRQ   = 100          // clock frequence in Mhz
) (
input           clk,
input           rst,
// cfg
input [1:0]     cfg_parity,
input [1:0]     cfg_stop_bits,
// tx path
input [7:0]     txdin,
input           txvalid,
output          ready,
output          uart_tx,
// rx path
input           uart_rx,
output [7:0]    rxdout,
output          rxvalid,
output          parity_err

/*AUTOINPUT*/

/*AUTOOUTPUT*/

);

/*AUTOWIRE*/

/*AUTOREG*/

uart_tx uart_tx
    (/*AUTOINST*/
     // Outputs
     .ready                             (ready),
     .uart_tx                           (uart_tx),
     // Inputs
     .clk                               (clk),
     .rst                               (rst),
     .cfg_parity                        (cfg_parity[1:0]),
     .cfg_stop_bits                     (cfg_stop_bits[1:0]),
     .txdin                             (txdin[7:0]),
     .txvalid                           (txvalid));


uart_rx uart_rx
    (/*AUTOINST*/
     // Outputs
     .rxdout                            (rxdout[7:0]),
     .rxvalid                           (rxvalid),
     .parity_err                        (parity_err),
     // Inputs
     .clk                               (clk),
     .rst                               (rst),
     .cfg_parity                        (cfg_parity[1:0]),
     .cfg_stop_bits                     (cfg_stop_bits[1:0]),
     .uart_rx                           (uart_rx));

endmodule
