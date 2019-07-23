
module k_floatcsum
(
	input logic[63:0] in0, in1,
	output logic[63:0] out
);
	
	k_floatsum sum0(.a(in0[31:0]), .b(in1[31:0]), .out(out[31:0]));
	k_floatsum sum1(.a(in0[63:32]), .b(in1[63:32]), .out(out[63:32]));

endmodule
