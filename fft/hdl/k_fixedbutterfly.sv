
module k_fixedbutterfly(
	input logic[15:0] in0, in1, twiddle, logic[1:0] scaling = 0,
	output logic[15:0] out0, out1
);

	wire[15:0] multiplied, out0_, out1_;
	logic[7:0] scaling_factor;

	k_fixedcsum sum0(.in0(in0), .in1(multiplied), .out(out0_));
	k_fixedcsum sum1(.in0(in0), .in1({-multiplied[15:8],-multiplied[7:0]}), .out(out1_));
	k_fixedcmult mult(.in0(in1), .in1(twiddle), .out(multiplied));
//		assign out0 = out0_>>scaling;
//		assign out1 = out1_>>scaling;

	always@(*)
		case(scaling)
			2'b00: scaling_factor=8'b01111111;
			2'b01: scaling_factor=8'b01000000;
			2'b10: scaling_factor=8'b00100000;
			2'b11: scaling_factor=8'b00010000;
			default: scaling_factor=8'b01111111;
		endcase

	k_fixedmult scale0(.in0(scaling_factor), .in1(out0_[7:0]), .out(out0[7:0]));
	k_fixedmult scale1(.in0(scaling_factor), .in1(out0_[15:8]), .out(out0[15:8]));
	k_fixedmult scale2(.in0(scaling_factor), .in1(out1_[7:0]), .out(out1[7:0]));
	k_fixedmult scale3(.in0(scaling_factor), .in1(out1_[15:8]), .out(out1[15:8]));

endmodule