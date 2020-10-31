///////////////////////////////////////////////////////////////
//
// Name: audio_controller_driver.h
// Created: 10/29/2020
//
// Description:
//  Audio Controller Driver header file
//
///////////////////////////////////////////////////////////////

#include "audio_controller_csr.h"
#include "alt_types.h"
#include "io.h"

// =======================================
// Function prototype
// =======================================

// check if i2c controller is idle
int audio_i2c_is_idle(alt_u32 audio_base);

// write a 24-bit command packet
// addr: register address
// data: register data
void audio_i2c_wr_cmd(alt_u32 audio_base, alt_u32 addr, alt_u32 data);

// select the data source
void audio_wr_src_sel(alt_u32 audio_base, int dac_sel, int adc_sel);

// init the audio controller
void audio_init(alt_u32 audio_base);

int audio_adc_fifo_empty(alt_u32 audio_base);
alt_u32 audio_adc_fifo_rd(alt_u32 audio_base);
int audio_dac_fifo_full(alt_u32 audio_base);
void audio_dac_fifo_wr(alt_u32 audio_base, alt_u32 data);
