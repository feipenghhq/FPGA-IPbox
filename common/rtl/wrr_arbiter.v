///////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 by Heqing Huang (feipenghhq@gamil.com)
//
// Project Name: N/A
// Module Name: wrr_arbiter
//
// Author: Heqing Huang
// Date Created: 11/08/2020
//
// ================== Description ==================
//
//  A Weighted Round Robin Arbiter.
//  Lower request has higher priority as long as it has credit
//
//  Algorithm:
//  1. At beginning, all the request get the credit as credit.
//  2. If there is only 1 request, it gets the grant and its credit is decreased by 1.
//  3. If there is more than one request, the lowest one has priority over others,
//     if it has credit, then it gets the grant and credit is decreased by 1.
//     if it has no credit, then the next lowest one has priority and repeat this
//     arbitration process.
//
///////////////////////////////////////////////////////////////////////////////

module wrr_arbiter #(
parameter WIDTH         = 4,
parameter CREDIT_WIDTH  = 4,        // credit width
parameter TOTAL_WIDTH   = CREDIT_WIDTH * WIDTH
) (
input                       clk,
input                       rst,
input  [TOTAL_WIDTH-1:0]    credits,        // credit signal for each request. Each field needs to be exact CREDIT_WIDTH length
input  [WIDTH-1:0]          req,
output [WIDTH-1:0]          grant,
output [WIDTH-1:0]          grant_flopped,  // flopped version of the grant
output [WIDTH-1:0]          credit_avail    // credit available
);

reg [CREDIT_WIDTH-1:0]  credit_q[WIDTH-1:0];
reg [WIDTH-1:0]         grant_q;

wire [CREDIT_WIDTH-1:0] credit[WIDTH-1:0];
wire [WIDTH-1:0]        self_mask[WIDTH-1:0];           // mask to mask the request from itself.
wire [WIDTH-1:0]        req_from_others;                // request from others not itself.
/* verilator lint_off UNOPTFLAT */
wire [WIDTH-1:0]        grant_from_lower;               // grant from lower request
/* verilator lint_on UNOPTFLAT */
wire [WIDTH-1:0]        each_credit_rst;
wire                    credit_rst;

// ================================
// Main process
// ================================

assign credit_rst = &each_credit_rst;

genvar i;
generate
for (i = 0; i < WIDTH; i = i + 1) begin: _

    assign credit[i] = credits[CREDIT_WIDTH*(i+1)-1:CREDIT_WIDTH*i];
    assign credit_avail[i] = (credit_q[i] != 0);
    assign each_credit_rst[i] = ~credit_avail[i];
    assign self_mask[i] = ~(1'b1 << i);
    assign req_from_others[i] = |(self_mask[i] & req);

    if (i > 0)
        assign grant_from_lower[i] = |grant[i-1:0];
    else
        assign grant_from_lower[i] = 0;
    assign grant[i] = req[i] & ((~req_from_others[i]) | (credit_avail[i] & ~grant_from_lower[i]));
    assign grant_flopped[i] = grant_q[i];

    always @(posedge clk) begin
        if (rst) begin
            credit_q[i] <= credit[i];
            grant_q[i] <= 1'b0;
        end
        else begin
            grant_q[i] <= grant[i];
            if (credit_rst) credit_q[i] <= credit[i];
            else if (grant[i] & credit_avail[i]) credit_q[i] <= credit_q[i] - 1'b1;
        end
    end
end
endgenerate


endmodule
