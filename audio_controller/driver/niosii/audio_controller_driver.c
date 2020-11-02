///////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 by Heqing Huang (feipenghhq@gamil.com)
//
// Name: audio_controller_driver.c
// Created: 10/29/2020
//
// Description:
//  Audio Controller Driver
//
///////////////////////////////////////////////////////////////////////////////

#include "audio_controller_driver.h"
#include "stdio.h"

    // initialize the configuration register
    const alt_u16 regs_init[10] = {
        0x0010, // R0: left line in gain 0dB
        0x0010, // R1: right line in gain 0dB
        0x0079, // R2: left headphone out volume 0dB
        0x0079, // R3: right headphone out volume 0dB
        0x0031, // R4: analog path selec line-in to adc, dac to line-out
        0x0001, // R5: digital audio: no filter, no de-emphasis
        0x0000, // R6: enable all power
        0x0001, // R7: digital interface, left-adjust, 16-bit resolution, Invert BCLK
        0x0000, // R8: 48K sampling rate
        0x0001  // R9: activate
    };

// check if i2c controller is idle
int audio_i2c_is_idle(alt_u32 audio_base)
{
    alt_u32 status;
    int     idle_bit;

    status = IORD_32DIRECT(audio_base, AUDIO_CONTROLLER__STATUS_ADDR);
    idle_bit = (int) AUDIO_CONTROLLER__STATUS__I2C_IDLE__get(status);
    return idle_bit;
}

// write a 24-bit command packet
void audio_i2c_wr_cmd(alt_u32 audio_base, alt_u32 addr, alt_u32 data)
{
    const int DATA_WIDTH = 9;
    const alt_u32 i2c_id = 0x1A;// 0b0011010
    alt_u32 data_field;
    alt_u32 reg_data;
    alt_u32 byte_1_0;
    alt_u32 byte_2;

    byte_2   = (i2c_id & 0x7f);     // 7 bit i2c address
    byte_2   = byte_2 << 1 | 0;     // 1 bit write
    byte_1_0 = (addr & 0x7f);       // 7 bit address
    byte_1_0 = byte_1_0 << DATA_WIDTH | (data & 0x1ff); // 9 bit data
    data_field = byte_2 << 16 | byte_1_0;
    printf("[INFO] I2C Write cmd. Addr: %x, Data = %x\n", (int) addr, (int) data);
    reg_data = (alt_u32) AUDIO_CONTROLLER__I2C_CTRL__set(1, data_field, i2c_id);

    IOWR_32DIRECT(audio_base, AUDIO_CONTROLLER__I2C_CTRL_ADDR, reg_data);
    reg_data = (alt_u32) AUDIO_CONTROLLER__I2C_CTRL__set(0, data_field, i2c_id);
    IOWR_32DIRECT(audio_base, AUDIO_CONTROLLER__I2C_CTRL_ADDR, reg_data);
}

// select the data source
void audio_wr_src_sel(alt_u32 audio_base, int dac_sel, int adc_sel)
{
    alt_u32 reg_data;

    reg_data = AUDIO_CONTROLLER__CTRL__set(adc_sel, dac_sel);
    IOWR_32DIRECT(audio_base, AUDIO_CONTROLLER__CTRL_ADDR, reg_data);
}


// init the audio controller
void audio_init(alt_u32 audio_base)
{

    int i;

    while(!audio_i2c_is_idle(audio_base)) {;}    // wait for I2C to be ready
    audio_i2c_wr_cmd(audio_base, 15, 0);         // reset the audio codec
    // config all the register
    for (i = 0; i < 10; i++) {
        while(!audio_i2c_is_idle(audio_base)) {;}
        audio_i2c_wr_cmd(audio_base, i, regs_init[i]);
    }
    audio_wr_src_sel(audio_base, 0, 0);         // select Avalon bus as ADC/DAC source
}

int audio_adc_fifo_empty(alt_u32 audio_base)
{
    alt_u32 status;
    int     adc_fifo_empty_bit;

    status = IORD_32DIRECT(audio_base, AUDIO_CONTROLLER__STATUS_ADDR);
    adc_fifo_empty_bit = (int) AUDIO_CONTROLLER__STATUS__ADC_FIFO_EMPTY__get(status);
    return adc_fifo_empty_bit;
}

alt_u32 audio_adc_fifo_rd(alt_u32 audio_base)
{
    alt_u32 data_reg;

    data_reg = (alt_u32) IORD_32DIRECT(audio_base, AUDIO_CONTROLLER__ADC_DATA_ADDR);
    return data_reg;
}

int audio_dac_fifo_full(alt_u32 audio_base)
{
    alt_u32 status;
    int     dac_fifo_full_bit;

    status = IORD_32DIRECT(audio_base, AUDIO_CONTROLLER__STATUS_ADDR);
    dac_fifo_full_bit = (int) AUDIO_CONTROLLER__STATUS__DAC_FIFO_FULL__get(status);
    return dac_fifo_full_bit;
}

void audio_dac_fifo_wr(alt_u32 audio_base, alt_u32 data)
{
    IOWR_32DIRECT(audio_base, AUDIO_CONTROLLER__DAC_DATA_ADDR, data);
}
