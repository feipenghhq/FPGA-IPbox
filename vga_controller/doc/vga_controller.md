# VGA Controller

- [VGA Controller](#vga-controller)
  - [Introduction](#introduction)
  - [Version](#version)
  - [Specification](#specification)
  - [Change Log](#change-log)
  - [Reference](#reference)

## Introduction

The VGA controller is design to display graph on monitor through the VGA interface

## Version

Ver 1.0

## Specification

The VGA controller consist of two main components: vga_sync and vga_vram_ctrl.

**vga_sync** is responsible for generating the vsync, hsync, and vga_video_on signals, it also outputs the address to retrieve the color pattern in frame buffer.

**vga_vram_ctrl** is responsible for generating control signals to access the video ram or frame buffer to get the pixel data. Because the vram implementation might be different, this is more like a general interface memory access.

### Some Implementation details

1. To simplify the design and to support various resolution, the VGA controller use it's own clock domain. The clock input to the VGA controller should be the exact required clock frequency for the specific resolution which is usually same as the pixel rate. CDC logic will be provided by the VGA controller to talk to the logic on other clock domain.

## Change Log

- 11/05/2020 - Version 1.0: Initial version created base on the old VGA controller design

## Reference

- *Embedded SoPC Design With NIOS II Processor and Verilog Example* by Pong Chu.
- VGA Signal Timing: <http://tinyvga.com/vga-timing>
