
module k_fixedsum(input logic[7:0] in0, in1, output logic[7:0] out);
	assign out = $signed(in0) + $signed(in1);
endmodule
