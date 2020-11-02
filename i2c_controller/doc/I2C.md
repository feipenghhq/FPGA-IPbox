# I<sup>2</sup>C Controller

- [I<sup>2</sup>C Controller](#isup2supc-controller)
  - [I<sup>2</sup>C Introduction](#isup2supc-introduction)
  - [I<sup>2</sup>C Master Controller IP](#isup2supc-master-controller-ip)
  - [Change Log](#change-log)

## I<sup>2</sup>C Introduction

I<sup>2</sup>C protocol is a low-speed serial bus protocol. The standard mode supports up to 100KHz clock rate. This version of the controller use the 2-wire mode.

The I<sup>2</sup>C contains two bidirectional signals: **SDA** (serial data) and **SCL** (serial clock). SDA is used to transfer data and SCL is the clock signal.

Each I<sup>2</sup>C device has a unique address and can operates as master or slaves.

### Electrical characteristics

The I<sup>2</sup>C bus uses open-drain technology. The SDA and SCL lines are connected to voltage source via a pull-up resistor. The SDA and SCL signals from all the devices are connected the SDA and SCL lines respectively.

<img src="https://upload.wikimedia.org/wikipedia/commons/3/3e/I2C.svg" alt="I2C"   />

<center style="font-size:14px;color:#C0C0C0;text-decoration:underline">Image taken from wikipedia</center>

### I<sup>2</sup>C operation

The basic operation of a I<sup>2</sup>C access cycle is as follow:

1. The master initiates a transfer by creating the **start** condition, where SDA changes from high to low while SCL is high. Master starts to drive the SCL lines as the clock signals

2. The master sends the **slave address (7 bits)** and the **access type** (1 bit) through the SDA line.
3. Slaves send **acknowledge (ACK)** through the SDA line by driving the SDA line low.
4. The data transfer is done on a byte-by-byte basis with MSB first. Depending on the access type (write/read), master or slave drives the first byte of **data (8 bits)** through SDA line.
5. Slaves send **acknowledge (ACK)** through the SDA line.
6. If there are more data to be transfer, repeat steps 4 and 5. If there are no more data to be transfered, master/slave sends **stop** condition, where the SDA changes from low to high while SCL is high

In summary: Start   => Send address and access type => Send data => Stop

| Operation | SDA              | SCL     |
| --------- | ---------------- | ------- |
| Start     | From high to low | High    |
| ACK       | Low              | Running |
| Stop      | From low to high | high    |

### Timing Diagram

![1 byte access](https://upload.wikimedia.org/wikipedia/commons/6/64/I2C_data_transfer.svg)

<center style="font-size:14px;color:#C0C0C0;text-decoration:underline">Image taken from wikipedia</center>

> This section is heavy referenced from the following material: 
>
> 1. Embedded SoPC Design with Nios II Processor and Verilog Examples. by Pong Chu

## I<sup>2</sup>C Master Controller IP

### Supported Feature

1. Configurable system clock and I2c clock frequency. Default system clock is 50 MHz,  I<sup>2</sup>C SCL is 100 KHz.

2. Configurable byte size and number of bytes to transfer in each transaction. 

3. Only support write operation for now. Read will be added later

## Change Log

- 10/30/2020:  Version 1.0 - Fixed bugs found in FPGA test.
- 10/25/2020:  Version 1.0 - Initial Version Created.