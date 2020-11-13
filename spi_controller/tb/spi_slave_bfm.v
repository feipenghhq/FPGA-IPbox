

module spi_slave_bfm #(
parameter DWIDTH = 8
) (
input              cpol,
input              cpha,

// SPI signal
input              sclk,   // SPI serial clock
input              mosi,   // Master Out Slave in
output reg         miso,   // Master in Slave out
input              cs,     // Chip select

// To env
output reg [DWIDTH-1:0] received_data,
output reg [DWIDTH-1:0] send_data
);

reg [DWIDTH-1:0] received_data_shifter;
reg [DWIDTH-1:0] send_data_shifter;

wire sclk_int;

integer i, j;

// invert the clk on cpol == 1 so we use the same edge to capture and shift.
assign sclk_int = cpol ? ~sclk : sclk;


// RX PATH
always @(*) begin
    i = 0;
    received_data_shifter = 0;
    wait(cs == 1);
    for (i = 0; i < DWIDTH; i = i + 1) begin
        if (cpha == 0) @(posedge sclk_int);
        else @(posedge sclk_int);
        received_data_shifter = {received_data_shifter[DWIDTH-2:0], mosi};
    end
    received_data = received_data_shifter;
end

// TX PATH
always @(*) begin
    j = 0;
    send_data_shifter = $random;
    send_data = send_data_shifter;
    wait(cs == 1);
    // skip the first shift if required
    if (cpha == 1) @(posedge sclk_int);
    miso = send_data_shifter[DWIDTH-1];
    for (j = 0; j < DWIDTH; j = j + 1) begin
        if (cpha == 0) @(posedge sclk_int);
        else @(posedge sclk_int);
        send_data_shifter = send_data_shifter << 1;
        miso = send_data_shifter[DWIDTH-1];
    end
end

endmodule