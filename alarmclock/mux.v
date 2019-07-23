module mux(
	input wire a, b, sel,
	output wire out
);
	assign out = sel ? a : b;
endmodule

module mux_tb;
	reg a, b, sel, out_expected;
	wire out;
	reg[3:0] read_data[0:7];

	integer i;

	initial begin
        	$readmemb("mux.txt", read_data);

		for (i=0; i<8; i=i+1) begin
			{a, b, sel, out_expected} = read_data[i];
	            	#20;
		end
        end

	always@(*) begin
		if(out != out_expected) $display("error at %b%b%b_%b.%b", a, b, sel, out_expected, out);
 	end

	mux DUT(.a(a), .b(b), .sel(sel), .out(out));
endmodule
