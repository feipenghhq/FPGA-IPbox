///////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 by Heqing Huang (feipenghhq@gamil.com)
//
// Project Name: VGA controller
// Module Name: N/A
//
// Author: Heqing Huang
// Date Created: 05/14/2019
//
// ================== Description ==================
//
//  Header file for VGA controller
//  The header defines different paramete for different resolution
//
//  See http://tinyvga.com/vga-timing
//  for more detail vga timing for different resoultion
//
///////////////////////////////////////////////////////////////////////////////


`define _VGA_640_480

`ifndef _VGA_VH_
`define _VGA_VH_

/////////////////
// VGA 640x480 //
/////////////////

// clock rate 25.125Mhz
`ifdef _VGA_640_480
    // Horizontal timing
    `define HVA 640		// visible area
    `define HFP 16		// front porch
    `define HSP 96		// sync pulse
    `define HBP 48		// back porch
    // Vertical timing
    `define VVA	480	// visible aread
    `define VFP 10		// front porch
    `define VSP	2		// sync pulse
    `define VBP 33		// back porch
    // other
    `define HCNT `HVA
    `define VCNT `VVA
`endif

//////////////////
// VGA 1600x900 //
//////////////////
// clock rate 108MHz
`ifdef _VGA_1600_900
    // Horizontal timing
    `define HVA 1600	// visible area
    `define HFP 24		// front porch
    `define HSP 80		// sync pulse
    `define HBP 96		// back porch
    // Vertical timing
    `define VVA	900		// visible area
    `define VFP 1		// front porch
    `define VSP	3		// sync pulse
    `define VBP 96		// back porch
    `define HCNT `HVA
    `define VCNT `VVA
`endif

`endif