
module k_floatdragonfly(
	input logic[63:0] in0, in1, in2, in3, twiddle0, logic[1:0] scaling = 0,
	output logic[63:0] out0, out1, out2, out3
);
//	wire[63:0] mult1, mult2, mult3, a0, a1, a2, _a3, a3, out0_, out1_, out2_, out3_;
//	logic[31:0] scaling_factor;
//	k_floatcmult cmult0(.in0(in1), .in1(twiddle0), .out(mult1));
//	k_floatcmult cmult1(.in0(in2), .in1(twiddle1), .out(mult2));
//	k_floatcmult cmult2(.in0(in3), .in1(twiddle2), .out(mult3));
//
//	k_floatcsum sum0(.in0(in0), .in1(mult2), .out(a0));
//	k_floatcsum sum1(.in0(in0), .in1({!mult2[63], mult2[62:32],!mult2[31], mult2[30:0]}), .out(a2));
//	
//	k_floatcsum sum2(.in0(mult1), .in1(mult3), .out(a1));
//	k_floatcsum sum3(.in0(mult1), .in1({!mult3[63], mult3[62:32],!mult3[31], mult3[30:0]}), .out(_a3));
//
//	assign a3 = {!_a3[31], _a3[30:0], _a3[63:32]};
//
//	k_floatcsum sum4(.in0(a0), .in1(a1), .out(out0_));
//	k_floatcsum sum5(.in0(a0), .in1({!a1[63], a1[62:32],!a1[31], a1[30:0]}), .out(out1_));
//
//	k_floatcsum sum6(.in0(a2), .in1(a3), .out(out2_));
//	k_floatcsum sum7(.in0(a2), .in1({!a3[63], a3[62:32],!a3[31], a3[30:0]}), .out(out3_));
//


	wire[63:0] mult1, mult2, mult3, a0, a1, a2, _a3, a3, out0_, out1_, out2_, out3_, twiddle1_, twiddle2_;
	logic[31:0] scaling_factor;
	
	k_floatcmult cmult3(.in0(twiddle0), .in1(twiddle0), .out(twiddle1_));
	k_floatcmult cmult4(.in0(twiddle1_), .in1(twiddle0), .out(twiddle2_));

	k_floatcmult cmult0(.in0(in1), .in1(twiddle1_), .out(mult1));
	k_floatcmult cmult1(.in0(in2), .in1(twiddle0), .out(mult2));
	k_floatcmult cmult2(.in0(in3), .in1(twiddle2_), .out(mult3));

	k_floatcsum sum0(.in0(in0), .in1(mult1), .out(a0));
	k_floatcsum sum1(.in0(in0), .in1({!mult1[63], mult1[62:32],!mult1[31], mult1[30:0]}), .out(a1));

	k_floatcsum sum2(.in0(mult2), .in1(mult3), .out(a2));
	k_floatcsum sum3(.in0(mult2), .in1({!mult3[63], mult3[62:32],!mult3[31], mult3[30:0]}), .out(_a3));

	assign a3 = {!_a3[31], _a3[30:0], _a3[63:32]};

	k_floatcsum sum4(.in0(a0), .in1(a2), .out(out0_));
	k_floatcsum sum5(.in0(a0), .in1({!a2[63], a2[62:32],!a2[31], a2[30:0]}), .out(out2_));

	k_floatcsum sum6(.in0(a1), .in1(a3), .out(out1_));
	k_floatcsum sum7(.in0(a1), .in1({!a3[63], a3[62:32],!a3[31], a3[30:0]}), .out(out3_));

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
	k_floatmult scale4(.a(scaling_factor), .b(out2_[31:0]), .out(out2[31:0]));
	k_floatmult scale5(.a(scaling_factor), .b(out2_[63:32]), .out(out2[63:32]));
	k_floatmult scale6(.a(scaling_factor), .b(out3_[31:0]), .out(out3[31:0]));
	k_floatmult scale7(.a(scaling_factor), .b(out3_[63:32]), .out(out3[63:32]));
endmodule