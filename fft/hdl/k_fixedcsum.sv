
module k_fixedcsum
(
	input logic[15:0] in0, in1,
	output logic[15:0] out
);
	
	k_fixedsum sum0(.in0(in0[7:0]), .in1(in1[7:0]), .out(out[7:0]));
	k_fixedsum sum1(.in0(in0[15:8]), .in1(in1[15:8]), .out(out[15:8]));

endmodule
