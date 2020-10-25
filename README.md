# FPGA IP Box

[TOC]

Some common and useful FPGA IP for my project.

## Arty-A7

IPs/Files for the Arty-A7 FPGA Board. 

More info: [DOC](./Arty-A7/doc/SPEC.md)



## Altera-DEX

IPs/Files for the Altera-DE series FPGA board. Currently Empty



## Common IPs/Files

Some common IPs/Files used across different modules. 

More info: [DOC](./common/doc/SPEC.md)



## SRAM Controller

An Avalon Memory SRAM controller. Designed for the SRAM chip Terasic DE1/DE2 FPGA board.

The SRAM chip used in the FPGA board is **IS61LV25616** from ISSI.

More info: [DOC](sram_controller/doc/avm_sram_controller.md)



## Uart

A simple uart core. Support both TX and RX path. No FIFO or data buffering.



## VGA

A simple VGA controller. Need an external Frame buffer.