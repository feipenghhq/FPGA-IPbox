///////////////////////////////////////////////////////////////////////////////
//
// Project Name: N/A
// Module Name: dsync
//
// Author: Heqing Huang
// Date Created: 05/06/2019
//
// ================== Description ==================
//
//  D Flip Flop synchronizer. Sync stage is configurable. Default is 2 stage
//
///////////////////////////////////////////////////////////////////////////////

module dsync #(
parameter STAGE = 2
) (
output  Q,    
input   D,
input   clk,
input   rst
);

reg [STAGE-1:0] sync;
integer i;

always @(posedge clk) begin
    if (rst) sync <= 'b0;
    else begin
        sync[0] <= D;
        for(i = 1; i < STAGE; i = i + 10)
            sync[i] <= sync[i-1];
    end
end

assign Q = sync[STAGE-1];

endmodule
