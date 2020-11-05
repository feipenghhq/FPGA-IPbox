///////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 by Heqing Huang (feipenghhq@gamil.com)
//
// Name: ps2_controller_driver.c
// Author: Heqing Huang
// Created: 11/01/2020
//
// Description:
//  PS2 Controller Driver for NIOS-II processor
//
///////////////////////////////////////////////////////////////////////////////

#include "ps2_controller_driver.h"


// ==============================
// write function
// ==============================

// check whether PS2 TX path is idle or not
int ps2_tx_is_idle(alt_u32 ps2_base)
{
    alt_u32 ps2_status;
    int     tx_fifo_full;

    ps2_status = (alt_u32) IORD_32DIRECT(ps2_base, PS2__STATUS_ADDR);
    tx_fifo_full = (int)  PS2__STATUS__TX_FIFO_FULL__get(ps2_status);
    return tx_fifo_full;
}

// check if the TX FIFO is full or not
int ps2_tx_fifo_full(alt_u32 ps2_base)
{
    alt_u32 ps2_status;
    int     tx_fifo_full;

    ps2_status = (alt_u32) IORD_32DIRECT(ps2_base, PS2__STATUS_ADDR);
    tx_fifo_full = (int)  PS2__STATUS__TX_FIFO_FULL__get(ps2_status);
    return tx_fifo_full;
}

// Send a command through PS2 to device, wait till the write is done
void ps2_wr_cmd_wait(alt_u32 ps2_base, alt_u8 cmd)
{
	alt_u32 reg_data;

	// wait till the FIFO is not full
	while(ps2_tx_fifo_full(ps2_base));
	reg_data = PS2__DATA__set(0, cmd);
	IOWR_32DIRECT(ps2_base, PS2__DATA_ADDR, reg_data);
}

// ==============================
// read function
// ==============================

// check if the receiving FIFO is empty or not
int ps2_rx_fifo_empty(alt_u32 ps2_base)
{
    alt_u32 ps2_status;
    int     rx_fifo_empty;

    ps2_status = (alt_u32) IORD_32DIRECT(ps2_base, PS2__STATUS_ADDR);
    rx_fifo_empty = (int)  PS2__STATUS__RX_FIFO_EMPTY__get(ps2_status);
    return rx_fifo_empty;
}

// Receive a data from FIFO
alt_u8 ps2_read_rx_fifo(alt_u32 ps2_base)
{
    alt_u32 reg_data;
    alt_u8  fifo_data;

    reg_data = (alt_u32) IORD_32DIRECT(ps2_base, PS2__DATA_ADDR);
    fifo_data = (alt_u8) PS2__DATA__RX_FIFO__get(reg_data);
    return fifo_data;
}

// check the FIFO and get a data if FIFO is not empty
int ps2_get_pkt(alt_u32 ps2_base, alt_u8 *byte)
{
    int rx_fifo_empty;

    rx_fifo_empty = ps2_rx_fifo_empty(ps2_base);
    if (!rx_fifo_empty) {
        *byte = ps2_read_rx_fifo(ps2_base);
    }
    return rx_fifo_empty;
}

// flush all the packets from the receiving FIFO
void ps2_flush_fifo(alt_u32 ps2_base)
{
    while(!ps2_rx_fifo_empty(ps2_base)) {
        ps2_read_rx_fifo(ps2_base);
    }
}
