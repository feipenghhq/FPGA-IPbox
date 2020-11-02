///////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 by Heqing Huang (feipenghhq@gamil.com)
//
// Project Name: Arty A7
// Module Name: pmod_7seg_display
//
// Author: Heqing Huang
// Date Created: 05/06/2019
//
// ================== Description ==================
//
//  7 segment display logic for the PMOD module.
//
//  Because the PMOD use the same ctrl pins for the two numbers, it
//  uses additional select bit to do time multiplexing between the two
//  display numbers.
//
///////////////////////////////////////////////////////////////////////////////

module pmod_7seg_display #(
parameter CLK_FREQ = 100,       // based on MHz
parameter BOUNCE_TIME = 50      // based on ms
) (
input               clk,
input               rst,
input [3:0]         numa,           // number A
input [3:0]         numb,           // number B
output reg [6:0]    out,            // 6 - 0: ABCDEFG
output reg          select
);

localparam SWITCH_CYCLE =  CLK_FREQ * BOUNCE_TIME;

reg [15:0]  counter;

logic [3:0] num;

// do time multiplexing here
always @(posedge clk) begin
    if(rst) begin
        counter <= 'b0;
        select <= 'b0;
    end
    else begin
        counter <= counter + 1;
        if (counter == SWITCH_CYCLE) begin
            counter <= 'b0;
            select <= ~select;
        end
    end
end

assign num = (select == 0) ? numa : numb;

// logic '1' will turn on the light
always_ff @(posedge clk) begin
    case(num)
    'h0: out <= 7'b1111110;
    'h1: out <= 7'b0110000;
    'h2: out <= 7'b1101101;
    'h3: out <= 7'b1111001;
    'h4: out <= 7'b0110011;
    'h5: out <= 7'b1011011;
    'h6: out <= 7'b1011111;
    'h7: out <= 7'b1110000;
    'h8: out <= 7'b1111111;
    'h9: out <= 7'b1110011;
    'hA: out <= 7'b1110111;
    'hB: out <= 7'b0011111;
    'hC: out <= 7'b1001110;
    'hD: out <= 7'b0111101;
    'hE: out <= 7'b1001111;
    'hF: out <= 7'b1000111;
    default: out <= 7'b???????;
    endcase
end

endmodule // seven_display


/* Backup information - Value Decode
 * upper case means the light is on,
INPUT VALUT	SEGMENTS LIT	OUTPUT VALUE
0	        A B C D E F	    7'b1111110
1	        B C	            7'b0110000
2	        A B D E G	    7'b1101101
3	        A B C D G	    7'b1111001
4	        B C F G	        7'b0110011
5	        A C D F G	    7'b1011011
6	        A C D E F G	    7'b1011111
7	        A B C	        7'b1110000
8	        A B C D E F G   7'b1111111
9	        A B C F G	    7'b1110011
A	        A B C E F G	    7'b1110111
b	        C D E F G	    7'b0011111
C	        A D E F	        7'b1001110
d	        B C D E G	    7'b0111101
E	        A D E F G	    7'b1001111
F	        A E F G	        7'b1000111
*/
