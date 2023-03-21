module switch_stabilizer (
	input clk, 

	input [15:0] sw_in, 
	output [15:0] sw_out
);

genvar i, j;

logic [15:0] sw_in_q [4:0];
logic [2:0] sw_in_s[15:0] ;

always @(posedge clk) begin
    sw_in_q[0] <= sw_in;
    sw_in_q[1] <= sw_in_q[0];
    sw_in_q[2] <= sw_in_q[1];
    sw_in_q[3] <= sw_in_q[2];
    sw_in_q[4] <= sw_in_q[3];
end

generate
for (j = 0; j < 16; j = j + 1) begin
    assign sw_in_s[j] = sw_in_q[0][j] + sw_in_q[1][j] + sw_in_q[2][j] + sw_in_q[3][j] + sw_in_q[4][j];
    assign sw_out[j] = (sw_in_s[j] > 2);
end
endgenerate




endmodule
