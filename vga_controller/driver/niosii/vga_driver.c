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

#include "vga_driver.h"
#include "io.h"
#include <stdlib.h>
#include <stdio.h>

#define X_MAX 640
#define Y_MAX 480

#define X_MASK 0x3FF
#define Y_MASK 0x1FF
#define X_SIZE 10
#define Y_SIZE 9

// calculate vram address
alt_u32 vga_calc_vram_addr(int x, int y) {
    alt_u32 addr;

    addr = (alt_u32) (((y & Y_MASK) << X_SIZE) | (x & X_MASK));
    return addr;
}

// read a pixel from vram
alt_u8 vga_rd_pixel(alt_u32 vram_base, int x, int y) {
    alt_u8 pixel;
    alt_u32 addr;

    addr = vga_calc_vram_addr(x, y);
    pixel = (alt_u8) IORD_8DIRECT(vram_base, addr);
    return pixel;
}

// write a pixel to vram
void vga_wr_pixel(alt_u32 vram_base, int x, int y, alt_u8 pixel){
    alt_u32 addr;
    addr = vga_calc_vram_addr(x, y);
    IOWR_8DIRECT(vram_base, addr, pixel);
}

// clear the screen
void vga_clr_screen(alt_u32 vram_base, alt_u8 pixel) {
    int x, y;

    printf("clear the screen!\n");
    for (x = 0; x < X_MAX; x++) {
        for ( y = 0; y < Y_MAX; y++) {
            vga_wr_pixel(vram_base, x, y, pixel);
        }
    }
    printf("clear the screen done!\n");

}

// helper function
void vga_swap_two_int(int *a, int *b) {
    int tmp;

    tmp = *a;
    *a = *b;
    *b = tmp;
}

// draw a line
// this function uses Bresenham's line algorithm
// https://en.wikipedia.org/wiki/Bresenham%27s_line_algorithm
void vga_draw_line(alt_u32 vram_base, int x0, int y0, int x1, int y1, alt_u8 pixel) {
    int steep;
    int dx, dy, error, ystep, y;
    int x;

    steep = abs(y1 - y0) > abs(x1 - x0);
    if (steep) {
        vga_swap_two_int(&x0, &y0);
        vga_swap_two_int(&x1, &y1);
    }

    if (x0 > x1) {
        vga_swap_two_int(&x0, &x1);
        vga_swap_two_int(&y0, &y1);
    }

    dx = x1 - x0;
    dy = abs(y1 - y0);
    error =  dx / 2;
    ystep = (y0 < y1) ? 1 : -1;
    y = y0;
    for (x = x0; x <= x1; x++) {
        if (steep) {
            vga_wr_pixel(vram_base, y, x, pixel);
        } else {
            vga_wr_pixel(vram_base, x, y, pixel);
        }
        if (error < 0) {
            y += ystep;
            error += dx;
        }
    }
}

void vga_draw_box(alt_u32 vram_base, int x0, int y0, int x1, int y1, alt_u8 pixel) {
	int x, y;

	if (x0 > x1) {
        vga_swap_two_int(&x0, &x1);
        vga_swap_two_int(&y0, &y1);
	}


	for (y = y0; y <= y1; y++) {
		for (x = x0; x <= x1; x++) {
			vga_wr_pixel(vram_base, x, y, pixel);
		}
	}
}

