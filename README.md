# FPGA IP Box

- [FPGA IP Box](#fpga-ip-box)
  - [Arty-A7](#arty-a7)
  - [Altera-DEX](#altera-dex)
  - [Common IPs/Files](#common-ipsfiles)
  - [SRAM Controller](#sram-controller)
  - [Uart](#uart)
  - [VGA](#vga)
  - [I<sup>2</sup>C Controller](#isup2supc-controller)
  - [Audio Controller](#audio-controller)

Some common and useful FPGA IP for my project.

## [Arty-A7](Arty-A7/doc/SPEC.md)

IPs/Files for the Arty-A7 FPGA Board.

## Altera-DEX

IPs/Files for the Altera-DE series FPGA board. Currently Empty

## [Common IPs/Files](common/doc/SPEC.md)

Some common IPs/Files used across different modules.

## [SRAM Controller](sram_controller/doc/avm_sram_controller.md)

An Avalon Memory SRAM controller. Designed for the SRAM chip (**IS61LV25616** from ISSI) used in Terasic DE1/DE2 FPGA board.

## Uart

A simple uart core. Support both TX and RX path. No FIFO or data buffering.

## VGA

A simple VGA controller. Need an external Frame buffer.

## [I<sup>2</sup>C Controller](i2c_controller/doc/I2C.md)

A simple I<sup>2</sup>C Controller.

## [Audio Controller](audio_controller/doc/audio_controller.md)

An audio controller for WM8731/WM8731L chip in DE2/DE1 FPGA board.