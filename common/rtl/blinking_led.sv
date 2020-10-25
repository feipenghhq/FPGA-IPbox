///////////////////////////////////////////////////////////////////////////////
//
// Project Name: N/A
// Module Name: blinking_led
//
// Author: Heqing Huang
// Date Created: 05/06/2019
//
// ================== Description ==================
//      FPGA Hello world - blinking the led.
//      Led will blink for 1 secend.
//
///////////////////////////////////////////////////////////////////////////////

module blinking_led #(
parameter LED = 4,         // number of LED
parameter CLKFREQ = 100    // clock frequency in Mhz
) (
input                   clk,
input                   rst,
output reg [LED-1:0]    led
);

localparam CYCLE = CLKFREQ * 1000000;
localparam WIDTH = $clog2(CYCLE);
localparam WIDTH2 = $clog2(LED);

reg [WIDTH-1:0] count;

always_ff @(posedge clk) begin
    if (rst) begin
        count <= 'b0;
        led   <= 'b1;
    end
    else begin
        if (count == CYCLE) begin
            count <= 'b0;
        end
        else begin
            count <= count + 1;
        end

        if (count == CYCLE) begin
           led <= {led[LED-2:0], led[LED-1]};
        end
    end
end

endmodule