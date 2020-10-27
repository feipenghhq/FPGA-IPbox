// I2C slave Bus-Function-Model
// The I2C BFM assumes that the I2C master will send 4 bytes.
module i2c_slave_bfm #(
    parameter       CLK_FREQ = 50,          // default 50  MHz system clock
    parameter       I2C_CLK_FREQ = 100,     // default 100 KHz I2C clock
    parameter       NUM_BYTE = 4,           // number of byte the controller needs to support, do not includes address/access
    parameter       BYTE_SIZE = 8,          // byte size (assume address size + 1 = byte size)
    parameter       DATA_WIDTH = NUM_BYTE * BYTE_SIZE
) (
    inout i2c_SDA,
    input i2c_SCL,
    // received data and addr
    output [BYTE_SIZE-2:0] r_addr,
    output                 r_access,
    output reg [BYTE_SIZE-1:0] r_byte0,
    output reg [BYTE_SIZE-1:0] r_byte1,
    output reg [BYTE_SIZE-1:0] r_byte2,
    output reg [BYTE_SIZE-1:0] r_byte3,
    output reg                 complete
);

parameter DELTA = 2;
integer i;

wire i2c_SDA_o;
wire i2c_SDA_i;
reg [BYTE_SIZE-1:0] addr_access;
reg i2c_SDA_w;

assign i2c_SDA = i2c_SDA_w ? 1'b0 : 1'bz;
assign i2c_SDA_i = i2c_SDA;

assign r_addr = addr_access[BYTE_SIZE-1:1];
assign r_access = addr_access[0];

always
begin
    i2c_SDA_w = 1'b0;
    complete = 1'b0;
    // Start condition
    wait(i2c_SCL == 1'b1);
    //wait(i2c_SDA == 1'b0);
    @(negedge i2c_SDA);
    #DELTA $display("[I2C BFM] SDA goes low. Start transaction at time %t", $time);
    // get the address
    receive_byte(addr_access);
    #DELTA $display("[I2C BFM] Received address: 0x%h at time %t", r_addr, $time);
    send_ack();
    // receive the next four byte
    receive_byte(r_byte3);
    #DELTA $display("[I2C BFM] Received byte3: 0x%h at time %t", r_byte3, $time);
    send_ack();
    receive_byte(r_byte2);
    #DELTA $display("[I2C BFM] Received byte2: 0x%h at time %t", r_byte2, $time);
    send_ack();
    receive_byte(r_byte1);
    #DELTA $display("[I2C BFM] Received byte1: 0x%h at time %t", r_byte1, $time);
    send_ack();
    receive_byte(r_byte0);
    send_ack();
    #DELTA $display("[I2C BFM] Received byte0: 0x%h at time %t", r_byte0, $time);
    wait(i2c_SCL == 1'b1);
    #DELTA $display("[I2C BFM] SCL goes high at time %t", $time);
    @(posedge i2c_SDA_i);
    #DELTA $display("[I2C BFM] SDA goes high at time %t", $time);
    complete = 1'b1;
    #DELTA $display("[I2C BFM] Transaction completed %t", $time);
end

// ================================================
// receive one byte
// ================================================
task receive_byte;
    output [BYTE_SIZE-1:0]  byte;
    begin
        byte = 0;
        i = 0;
        while (i < BYTE_SIZE) begin
            @(posedge i2c_SCL) begin
                byte = (byte << 1'b1) | i2c_SDA;
                i = i + 1;
            end
        end
    end
endtask

task send_ack;
    begin
        @(negedge i2c_SCL);
        #DELTA i2c_SDA_w = 1'b1;
        @(negedge i2c_SCL);
        #DELTA i2c_SDA_w = 1'b0; // release sda
    end
endtask

endmodule