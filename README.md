# FPGA-IPbox

[TOC]

Some common and useful FPGA IP.

## Arty-A7

Some utilities for the Arty-A7 FPGA Board

| File                 | Description                                   |
| -------------------- | --------------------------------------------- |
| Arty_Top.v           | A simple top level file for the Arty-A7 board |
| pmod_7seg_display.sv | Pmod seven segment display driver             |



## Altera-DEX

Some IPs for the Altera-DE series FPGA board

| IPs                 | Description                          | Board |
| ------------------- | ------------------------------------ | ----- |
| avm_sram_controller | Avalon Memory Mapped SRAM Controller | DE2   |
|                     |                                      |       |
|                     |                                      |       |



## Common

Some common utilities used across different modules

| File            | Description                             |
| --------------- | --------------------------------------- |
| blinking_led.sv | Blink the LED. FPGA Hello World program |
| fifo.sv         | Basic synchronous FIFO                  |
| dsync.sv        | 2 Stage D Flip Flop synchronizer        |



## Uart

A simple uart core. Support both TX and RX path. No FIFO or data buffering.



## VGA

A simple VGA controller. Need an external Frame buffer.