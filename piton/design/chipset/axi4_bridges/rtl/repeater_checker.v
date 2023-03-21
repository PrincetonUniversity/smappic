module repeater_checker (
	input clk,    // Clock
	input rst_n,  // Asynchronous reset active low

	input val1, 
	input [63:0] dat1, 
	input rdy1, 

	input val2, 
	input rdy2, 
	input [63:0] dat2

);

localparam BUFSIZE=64;
localparam PTR_WIDTH=6;

reg [63:0] buffer [BUFSIZE];
reg [PTR_WIDTH-1:0] in;
reg [PTR_WIDTH-1:0] out;
reg overflow;
reg extradata;
reg error;


wire go1 = rdy1 & val1;
wire go2 = rdy2 & val2;

always @(posedge clk) begin
	if(~rst_n) begin
		in <= 0;
		out <= 0;
		overflow <= 0;
		extradata <= 0;
		error <= 0;
	end 
	else begin
		if (go1) begin
			in <= in + 6'd1;
			if (in + 6'd1 == out) begin
				overflow <= 1;
			end
			buffer[in] <= dat1; 
		end
		if (go2) begin
			out <= out + 6'd1;
			if (out == in) begin
				extradata <= 1;
			end
			if (dat2 != buffer[out]) begin
				error <= 1;
			end
		end
	end
end


endmodule 