
module k_fixeddragonfly(
	input logic[15:0] in0, in1, in2, in3, twiddle0, logic[1:0] scaling = 0,
	output logic[15:0] out0, out1, out2, out3
);
	wire[15:0] mult1, mult2, mult3, ra0, ra1, ra2, _ra3, ra3, a0, a1, a2, a3, out0_, out1_, out2_, out3_, twiddle1_, twiddle2_;
	logic[7:0] scaling_factor;
	
	k_fixedcmult cmult3(.in0(twiddle0), .in1(twiddle0), .out(twiddle1_));
	k_fixedcmult cmult4(.in0(twiddle1_), .in1(twiddle0), .out(twiddle2_));

	k_fixedcmult cmult0(.in0(in1), .in1(twiddle1_), .out(mult1));
	k_fixedcmult cmult1(.in0(in2), .in1(twiddle0), .out(mult2));
	k_fixedcmult cmult2(.in0(in3), .in1(twiddle2_), .out(mult3));

	k_fixedcsum sum0(.in0(in0), .in1(mult1), .out(ra0));
	k_fixedcsum sum1(.in0(in0), .in1({-mult1[15:8],-mult1[7:0]}), .out(ra1));

	k_fixedcsum sum2(.in0(mult2), .in1(mult3), .out(ra2));
	k_fixedcsum sum3(.in0(mult2), .in1({-mult3[15:8],-mult3[7:0]}), .out(_ra3));

	assign ra3 = {-_ra3[7:0], _ra3[15:8]};

	k_fixedcsum sum4(.in0(a0), .in1(a2), .out(out0_));
	k_fixedcsum sum5(.in0(a0), .in1({-a2[15:8],-a2[7:0]}), .out(out2_));

	k_fixedcsum sum6(.in0(a1), .in1(a3), .out(out1_));
	k_fixedcsum sum7(.in0(a1), .in1({-a3[15:8],-a3[7:0]}), .out(out3_));
	assign scaling_factor=8'b01000000;
//	always@(*)
//		case(scaling)
//			2'b00: scaling_factor=8'b01111111;
//			2'b01: scaling_factor=8'b01000000;
//			2'b10: scaling_factor=8'b00100000;
//			2'b11: scaling_factor=8'b00010000;
//			default: scaling_factor=8'b01111111;
//		endcase
	k_fixedmult scale0(.in0(scaling_factor), .in1(out0_[7:0]), .out(out0[7:0]));
	k_fixedmult scale1(.in0(scaling_factor), .in1(out0_[15:8]), .out(out0[15:8]));
	k_fixedmult scale2(.in0(scaling_factor), .in1(out1_[7:0]), .out(out1[7:0]));
	k_fixedmult scale3(.in0(scaling_factor), .in1(out1_[15:8]), .out(out1[15:8]));
	k_fixedmult scale4(.in0(scaling_factor), .in1(out2_[7:0]), .out(out2[7:0]));
	k_fixedmult scale5(.in0(scaling_factor), .in1(out2_[15:8]), .out(out2[15:8]));
	k_fixedmult scale6(.in0(scaling_factor), .in1(out3_[7:0]), .out(out3[7:0]));
	k_fixedmult scale7(.in0(scaling_factor), .in1(out3_[15:8]), .out(out3[15:8]));

	k_fixedmult scale00(.in0(scaling_factor), .in1(ra0[7:0]), .out(a0[7:0]));
	k_fixedmult scale01(.in0(scaling_factor), .in1(ra0[15:8]), .out(a0[15:8]));
	k_fixedmult scale02(.in0(scaling_factor), .in1(ra1[7:0]), .out(a1[7:0]));
	k_fixedmult scale03(.in0(scaling_factor), .in1(ra1[15:8]), .out(a1[15:8]));
	k_fixedmult scale04(.in0(scaling_factor), .in1(ra2[7:0]), .out(a2[7:0]));
	k_fixedmult scale05(.in0(scaling_factor), .in1(ra2[15:8]), .out(a2[15:8]));
	k_fixedmult scale06(.in0(scaling_factor), .in1(ra3[7:0]), .out(a3[7:0]));
	k_fixedmult scale07(.in0(scaling_factor), .in1(ra3[15:8]), .out(a3[15:8]));
endmodule