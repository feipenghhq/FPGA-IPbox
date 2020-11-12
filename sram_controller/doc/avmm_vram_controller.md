# Avalon Memory Mapped VRAM Controller

- [Avalon Memory Mapped VRAM Controller](#avalon-memory-mapped-vram-controller)
  - [Introduction](#introduction)
  - [Version](#version)
  - [Document](#document)
  - [Change Log](#change-log)

## Introduction

The Avalon Memory VRAM controller IP is designed for the **IS61LV25616** SRAM chip in Terasic DE1/DE2 FPGA board.

In this IP, the SRAM is used as VRAM (Video RAM or Frame buffer). It provides read interface for VGA controller and read/write interface for CPU/GPU. Both interface are avalon memory mapped interface. Other similar IPs using this access scheme can utilize this IP.

## Version

Ver 1.0

## Document

1. This IP supports fixed 8 bit data width. Since the SRAM is 16 bit wide, the LSb is used as byte select to select between the upper/lower byte.

2. Because there is only one port in the SRAM, arbitration is required between the VGA interface and CPU/GPU interface. A credit based weighted round-robin arbitration scheme is used in this design. The arbitration rules are as follows:
    1. If there is only 1 request (either CPU/GPU or VGA) at the time, it gets the grant and its credit is decreased by 1.
    2. If both are requesting, then VGA gets the grant if it has the credit. If it does not have the credit than CPU/GPU gets the grant.

3. The two interfaces get the specified credit upon reset. When both sides run out of credits, credits reset to the initial value.

4. This is a fully pipelined design so it will not block the incoming request in the next cycle. Each operation takes 3 clock cycles to completes so read latency is 2.

## Change Log

- 11/08/2020: Revision 1.0 - Initial Version.
