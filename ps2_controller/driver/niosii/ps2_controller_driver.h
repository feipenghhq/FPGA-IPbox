///////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 by Heqing Huang (feipenghhq@gamil.com)
//
// Name: ps2_controller_driver.h
// Author: Heqing Huang
// Created: 11/01/2020
//
// Description:
//  PS2 Controller Driver Header File
//
///////////////////////////////////////////////////////////////////////////////

#include "ps2_csr.h"
#include "system.h"
#include "alt_types.h"
#include "io.h"

// ==============================
// write function
// ==============================

// check whether PS2 TX path is idle or not
int ps2_tx_is_idle(alt_u32 ps2_base);
// check if the TX FIFO is fill or not
int ps2_tx_fifo_full(alt_u32 ps2_base);
// Send a command through PS2 to device, wait till the write is done
void ps2_wr_cmd_wait(alt_u32 ps2_base, alt_u8 cmd);

// ==============================
// read function
// ==============================

// check if the receiving FIFO is empty or not
int ps2_rx_fifo_empty(alt_u32 ps2_base);
// Receive a data from FIFO
alt_u8 ps2_read_rx_fifo(alt_u32 ps2_base);
// check the FIFO and get a data if FIFO is not empty
int ps2_get_pkt(alt_u32 ps2_base, alt_u8 *byte);
// flush all the packets from the receiving FIFO
void ps2_flush_fifo(alt_u32 ps2_base);
