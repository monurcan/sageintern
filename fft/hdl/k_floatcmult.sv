module k_floatcmult
(
	input logic[63:0] in0, in1,
	output logic[63:0] out
);
	// floatingde padding olmaz zaten 32=8k, padding 8'e tamamlamak icin
	wire[31:0] re0re1, im0im1, re0im1, im0re1;
	k_floatmult mult0(.a(in0[31:0]), .b(in1[31:0]), .out(re0re1));
	k_floatmult mult1(.a(in0[63:32]), .b(in1[63:32]), .out(im0im1));
	k_floatmult mult2(.a(in0[31:0]), .b(in1[63:32]), .out(re0im1));
	k_floatmult mult3(.a(in0[63:32]), .b(in1[31:0]), .out(im0re1));
	
	k_floatsum sum0(.a(re0re1), .b({!im0im1[31], im0im1[30:0]}), .out(out[31:0]));
	k_floatsum sum1(.a(im0re1), .b(re0im1), .out(out[63:32]));

endmodule
