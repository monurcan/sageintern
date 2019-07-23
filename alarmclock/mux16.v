module mux16(
	input wire[15:0] a, b, wire sel,
	output wire[15:0] out
);
	assign out = sel ? a : b;
endmodule

module mux16_tb;
	reg[15:0] a, b, out_expected, read_data[0:18];
	reg sel;
	wire[15:0]out;

	integer i;

	initial begin
        	$readmemb("mux16.txt", read_data);
		for(i=0; i<4; i=i+1) begin
			a = read_data[4*i];
			b = read_data[4*i+1];
			sel = read_data[4*i+2];
			out_expected = read_data[4*i+3];
	            	#20;
		end
        end

	mux16 DUT(.a(a), .b(b), .sel(sel), .out(out));
endmodule