// A simple queue model for the testbench
module queue #(
parameter DW = 32,
parameter SIZE = 1024
) (
input           push,
input [DW-1:0]  push_data,
input           pop,
output reg [DW-1:0] pop_data
);

reg [$clog2(SIZE)-1:0] wrptr = 0;
reg [$clog2(SIZE)-1:0] rdptr = 0;
reg [DW-1:0]           mem[SIZE-1:0];

always @(push) begin
    mem[wrptr] = push_data;
    wrptr = wrptr + 1;
end

always @(pop) begin
    pop_data = mem[rdptr];
    rdptr = rdptr + 1;
end

endmodule