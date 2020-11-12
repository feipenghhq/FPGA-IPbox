///////////////////////////////////////////////////////////////
//
// Copyright 2020 by Heqing Huang (feipenghhq@gamil.com)
//
// Name: bmp_reader.c
// Created: 11/09/2020
//
// Description:
//
// Provides functions to read a bmp file and draw it through VGA
//
///////////////////////////////////////////////////////////////


#include <stdio.h>
#include "bmp_reader.h"

// header size in byte
#define HEADER_SIZE 14

// header size in byte
#define INFO_HEADER_SIZE 40

#define read_8bit(data, fptr) fread(&data, sizeof(alt_u8), 1, fptr)
#define read_16bit(data, fptr) fread(&data, sizeof(alt_u16), 1, fptr)
#define read_32bit(data, fptr) fread(&data, sizeof(alt_u32), 1, fptr)

typedef struct bmpHeader {
    alt_u16 signature;
    alt_u32 fileSize;
    alt_u32 reserved;
    alt_u32 dataOffset;
} bmpHeader_t;

typedef struct bmpInfoHeader {
    alt_u32 size;
    alt_u32 width;
    alt_u32 height;
    alt_u16 planes;
    alt_u16 bitPerPixel;
    alt_u32 compressio;
    alt_u32 imageSize;
    alt_u32 xpixelsPerM;
    alt_u32 ypixelsPerM;
    alt_u32 colorUsed;
    alt_u32 importantColor;
} bmpInfoHeader_t;

void readHeader(FILE *bmp, bmpHeader_t *bmpHeader)
{
    read_16bit(bmpHeader->signature, bmp);
    read_32bit(bmpHeader->fileSize, bmp);
    read_32bit(bmpHeader->reserved, bmp);
    read_32bit(bmpHeader->dataOffset, bmp);

}

void readInfoHeader(FILE *bmp, bmpInfoHeader_t *bmpInfoHeader)
{
    read_32bit(bmpInfoHeader->size, bmp);
    read_32bit(bmpInfoHeader->width, bmp);
    read_32bit(bmpInfoHeader->height, bmp);
    read_16bit(bmpInfoHeader->planes, bmp);
    read_16bit(bmpInfoHeader->bitPerPixel, bmp);
    read_32bit(bmpInfoHeader->compressio, bmp);
    read_32bit(bmpInfoHeader->imageSize, bmp);
    read_32bit(bmpInfoHeader->xpixelsPerM, bmp);
    read_32bit(bmpInfoHeader->ypixelsPerM, bmp);
    read_32bit(bmpInfoHeader->colorUsed, bmp);
    read_32bit(bmpInfoHeader->importantColor, bmp);
}

// read out the remaining header
void readOtherHeader(FILE *bmp, alt_u32 dataOffset)
{
    int i;
    alt_u8 _;

    for (i = HEADER_SIZE + INFO_HEADER_SIZE; i < dataOffset; i ++) {
        read_8bit(_, bmp);
    }
}

// read the next pixel from the file
void readPixel(FILE *bmp, pixel_t *pixel) {
    read_8bit((pixel->b), bmp);
    read_8bit((pixel->g), bmp);
    read_8bit((pixel->r), bmp);
}


// read and draw a line of the picture
void drawPicLine(FILE *bmp, int y, alt_u32 width, alt_u32 paddingSize, alt_u32 vram_base, int x0)
{
    pixel_t pixel;
    alt_u8 r, g, b, p;
    alt_u32 x;
    alt_u8 _;

    for (x = x0; x < width + x0; x++) {
        readPixel(bmp, &pixel);
        r = pixel.r & 0xE0;
        g = (pixel.g & 0xE0) >> 3;
        b = (pixel.b & 0xE0) >> 6;
        p = r | g | b;
        vga_wr_pixel(vram_base, x, y, p);
    }

    // read out the padding
    for (x = 0; x < paddingSize; x++) {
        read_8bit(_, bmp);
    }
}

void drawAllPicLine(FILE *bmp, alt_u32 height, alt_u32 width, alt_u32 vram_base, int x0, int y0)
{
    alt_u32 paddingSize;
    alt_u32 lineSize;  // line size in byte = width * 3
    int y;

    // width * 3 = width + width * 2
    lineSize = width + (width << 1);
    paddingSize = (4 - (lineSize & 0x3)) & 0x3;

    // picture is store from bottom to up
    // somehow the following does not work. y does not stop at 0
    // for (y = height - 1; y >= 0; y--) {
    for (y = y0 + height - 1; y >= y0; y--) {
        drawPicLine(bmp, y-1, width, paddingSize, vram_base, x0);
    }
}

void drawPicture(char *file, alt_u32 vram_base, int x0, int y0)
{
    FILE *bmp;
    bmpHeader_t bmpHeader;
    bmpInfoHeader_t bmpInfoHeader;

	usleep(10000);
    bmp = fopen(file, "r");

    if (bmp == 0) {
    	fprintf(stderr, "Error: Can't open file %s\n", file);
    	return;
    }

    readHeader(bmp, &bmpHeader);
    readInfoHeader(bmp, &bmpInfoHeader);

    #ifdef DBGPRINT
        printf("FileName: %s\n", file);
        printf("FileSize: %d\n", bmpHeader.fileSize);
        printf("DataOffset: %d\n", bmpHeader.dataOffset);
        printf("Size: %d\n", bmpInfoHeader.size);
        printf("Width: %d\n", bmpInfoHeader.width);
        printf("Height: %d\n", bmpInfoHeader.height);
    #endif

    drawAllPicLine(bmp, bmpInfoHeader.height, bmpInfoHeader.width, vram_base, x0, y0);

    fclose(bmp);
}
