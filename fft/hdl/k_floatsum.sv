// for testing purposes, not synthesizable
module k_floatsum(input logic[31:0] a, b, output logic[31:0] out);
	shortreal in_0, in_1, out_;
	assign in_0 = $bitstoshortreal(a);
	assign in_1 = $bitstoshortreal(b);
	assign out_ = in_0 + in_1;
	assign out = $shortrealtobits(out_);
endmodule