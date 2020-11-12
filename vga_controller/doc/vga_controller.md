# VGA Controller

- [VGA Controller](#vga-controller)
  - [Introduction](#introduction)
  - [Version](#version)
  - [Document](#document)
  - [Change Log](#change-log)
  - [Reference](#reference)

## Introduction

The VGA controller is design to display graph on monitor through the VGA interface.

This controller currently support resolution of 640x480. It can be modified for other resolution.

VGA controller is running in its own clock domain (clk_vga), an async FIFO is provided to do clock crossing between clk_vga and the main system clock.

## Version

Ver 1.0

## Document

### General Structure

The VGA controller consists of two components: vga_sync, vga_vram_ctrl and a wrapper vga_controller.

**vga_sync** is responsible for generating the vsync, hsync, and vga_video_on signals, it also outputs the address to retrieve the color pattern in frame buffer.

**vga_vram_buffer** contains an async FIFO buffer to buffer the pixel data from the frame buffer (vram) and also do the cdc crossing. It also generate memory mapped read interface access the frame buffer to get the pixel data.

**vga_controller** instantiates the above two modules and it also expends the pixel data from vga_vram_buffer into separate R/G/B channels.

### VGA VRAM Buffer

To decouple the VGA core logic and the VRAM implementation, an async-FIFO is provided at the vga_vram_buffer module. On the read side, the VGA core logic will read the pixel data from the async FIFO. On the write side, a control logic fetches the future pixel data from the VRAM.

The VRAM buffer acts like a streaming interface to the VGA controller, so it is important to make sure that the pixel data fetched from the VRAM buffer matches the expected pixel being sent currently. Since there is really nothing we can do at the VGA side, this should be guaranteed by the write side. The vram read logic should fill the FIFO with the correct pixel sequence i.e. pixel at <0,0>, <0,1>, ... and it should make sure the FIFO is not empty during any operation time. So we should make sure the pixel fetch path has enough bandwidth.

Once the FIFO becomes empty during normal operation, the pixel data will be out of sync. We have to reset the vga controller in this case.

### [DE2 Board Specific Implementation] IS61LV25616 SRAM as VRAM and Supported Color Width

Because I am mainly using the Terasic DE2 board. I decide to use the SRAM in the board as the VRAM. The size of the SRAM is 256K x 16bit = 512 KByte.

For a 640x480 resolution VGA display, we need at least 640x480 = 303K pixel location. And since the x, y resolution is not a power of 2, to simplify the VRAM address calculation, we will extend the resolution to 1024x512 so the address calculation is just simply concatenate the pixel location
so we need 512K pixel location.

So each pixel will be represented by 8 bits which is also known as 8-bit color. The bit and RGB is divided as follow:

| Bit  | 7   | 6   | 5   | 4   | 3   | 2   | 1   | 0   |
| ---- | --- | --- | --- | --- | --- | --- | --- | --- |
| Data | R   | R   | R   | G   | G   | G   | B   | B   |

The actual R, G, B data might requires more bits depending on the DAC used to drive the VGA signal. To provide flexibility,
the RGB data width is configurable. The RGB data in the 8-bit color pattern will be extended by adding zeros to at end to the bit width defined in the design.

## Change Log

- 11/11/2020 - Version 1.0: Completed version 1.0 design. Tested the design in FPGA.
- 11/05/2020 - Version 1.0: Initial version created base on the old VGA controller design

## Reference

- *Embedded SoPC Design With NIOS II Processor and Verilog Example* by Pong Chu.
- VGA Signal Timing: <http://tinyvga.com/vga-timing>
