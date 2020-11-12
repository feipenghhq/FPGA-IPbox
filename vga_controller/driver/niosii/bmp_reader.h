///////////////////////////////////////////////////////////////
//
// Copyright 2020 by Heqing Huang (feipenghhq@gamil.com)
//
// Name: bmp_reader.h
// Created: 11/09/2020
//
// Description:
//
// Read a bmp file and draw it through VGA
//
///////////////////////////////////////////////////////////////

#include "vga_driver.h"
#include "system.h"
#include "alt_types.h"

typedef struct pixel {
    alt_u8 r;
    alt_u8 g;
    alt_u8 b;
} pixel_t;


void drawPicture(char *file, alt_u32 vram_base, int x0, int y0);
