
///////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 by Heqing Huang (feipenghhq@gamil.com)
//
// Name: vga_driver.c
// Created: 11/09/2020
//
// Description:
//
// A simple VGA driver. Provide functions to draw pixel in the screen by
// writing data into VRAM.
//
///////////////////////////////////////////////////////////////////////////////


#include "alt_types.h"
#include "system.h"


alt_u32 vga_calc_vram_addr(int x, int y);

alt_u8 vga_rd_pixel(alt_u32 vram_base, int x, int y);

void vga_wr_pixel(alt_u32 vram_base, int x, int y, alt_u8 pixel);

void vga_clr_screen(alt_u32 vram_base, alt_u8 pixel);

void vga_draw_line(alt_u32 vram_base, int x0, int y0, int x1, int y1, alt_u8 pixel);

void vga_draw_box(alt_u32 vram_base, int x0, int y0, int x1, int y1, alt_u8 pixel);

