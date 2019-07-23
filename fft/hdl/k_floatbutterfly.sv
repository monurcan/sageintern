
module k_floatbutterfly(
	input logic[63:0] in0, in1, twiddle, logic[1:0] scaling = 0,
	output logic[63:0] out0, out1
);

	wire[63:0] multiplied, out0_, out1_;
	logic[31:0] scaling_factor;

	k_floatcsum sum0(.in0(in0), .in1(multiplied), .out(out0_));
	k_floatcsum sum1(.in0(in0), .in1({!multiplied[63], multiplied[62:32],!multiplied[31], multiplied[30:0]}), .out(out1_));
	k_floatcmult mult(.in0(in1), .in1(twiddle), .out(multiplied));
//		assign out0 = out0_>>scaling;
//		assign out1 = out1_>>scaling;
//	

	always@(*)
		case(scaling)
			2'b00: scaling_factor=32'b00111111100000000000000000000000;
			2'b01: scaling_factor=32'b00111111000000000000000000000000;
			2'b10: scaling_factor=32'b00111110100000000000000000000000;
			2'b11: scaling_factor=32'b00111110000000000000000000000000;
			default: scaling_factor=32'b00111111100000000000000000000000;
		endcase

	k_floatmult scale0(.a(scaling_factor), .b(out0_[31:0]), .out(out0[31:0]));
	k_floatmult scale1(.a(scaling_factor), .b(out0_[63:32]), .out(out0[63:32]));
	k_floatmult scale2(.a(scaling_factor), .b(out1_[31:0]), .out(out1[31:0]));
	k_floatmult scale3(.a(scaling_factor), .b(out1_[63:32]), .out(out1[63:32]));

endmodule
