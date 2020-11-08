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

### 1. General Structure

The VGA controller consists of two components: vga_sync and vga_vram_ctrl.

**vga_sync** is responsible for generating the vsync, hsync, and vga_video_on signals, it also outputs the address to retrieve the color pattern in frame buffer.

**vga_vram_ctrl** is responsible for generating control signals to access the video ram or frame buffer to get the pixel data.

To simplify the design and to support various resolution, the VGA controller use it's own clock domain. The VGA controller clock speed should be the same as the pixel rate. CDC logic will be provided by the VGA controller to talk to the logic on other clock domain.

### 2. VGA Pixel Buffer

To decouple the VGA core logic and the VRAM implementation, an async-FIFO will be provided at the vga_vram_ctrl module. The VGA core logic will read the pixel data from the async-FIFO directly. And on the other side, there is a control logic to pre-fetch the future pixel data from the actual VRAM. This control logic will be a simple memory read logic.

The async-FIFO also provides the CDC function between the VGA core logic and the other logic.

### 2. IS61LV25616 SRAM as VRAM and Color Width

Because I am mainly using the Terasic DE2 board. I decide to use the SRAM in the board as the VRAM. The size of the SRAM is 256K x 16bit = 512 KByte.

For a 640x480 resolution VGA display, we need at least 640x480 = 303K pixel location. And since the x, y resolution is not a power of 2, to simplify the VRAM address calculation, we will extend the resolution to 1024x512 so we need 512K pixel location.

So each pixel will be represented by 8 bits which is also known as 8-bit color. The bit and RGB is divided as follow:

| Bit  | 7   | 6   | 5   | 4   | 3   | 2   | 1   | 0   |
| ---- | --- | --- | --- | --- | --- | --- | --- | --- |
| Data | R   | R   | R   | G   | G   | G   | B   | B   |

The actual R, G, B data might requires more bits depending on the DAC used to drive the VGA signal. To provide flexibility,
the RGB data width is configurable. The RGB data in the 8-bit color pattern will be extended by adding zeros to at end to the bit width defined in the design.

## Change Log

- 11/05/2020 - Version 1.0: Initial version created base on the old VGA controller design

## Reference

- *Embedded SoPC Design With NIOS II Processor and Verilog Example* by Pong Chu.
- VGA Signal Timing: <http://tinyvga.com/vga-timing>
