module k_fixedcmult
(
	input logic[15:0] in0, in1,
	output logic[15:0] out
);
	// fixedde padding olmaz zaten 8=8k, padding 8'e tamamlamak icin
	wire[7:0] re0re1, im0im1, re0im1, im0re1;
	k_fixedmult mult0(.in0(in0[7:0]), .in1(in1[7:0]), .out(re0re1));
	k_fixedmult mult1(.in0(in0[15:8]), .in1(in1[15:8]), .out(im0im1));
	k_fixedmult mult2(.in0(in0[7:0]), .in1(in1[15:8]), .out(re0im1));
	k_fixedmult mult3(.in0(in0[15:8]), .in1(in1[7:0]), .out(im0re1));
	
	k_fixedsum sum0(.in0(re0re1), .in1(-im0im1[7:0]), .out(out[7:0]));
	k_fixedsum sum1(.in0(im0re1), .in1(re0im1), .out(out[15:8]));

endmodule 
