module encoder(
	input wire[3:0] number,
	output reg[6:0] out
);

	always@* begin
		case(number)
			4'd0: out = 7'b0111111;
			4'd1: out = 7'b0000110;
			4'd2: out = 7'b1011011;
			4'd3: out = 7'b1001111;
			4'd4: out = 7'b1100110;
			4'd5: out = 7'b1101101;
			4'd6: out = 7'b1111101;
			4'd7: out = 7'b0000111;
			4'd8: out = 7'b1111111;
			4'd9: out = 7'b1100111;
			default: out = 7'b1111001;
		endcase
	end
endmodule

module encoder_test();
	wire[6:0] out;
	reg [3:0] number;
	encoder DUT(number,out);

	initial begin
		number = 4'd5;
		#50
		if(out != 7'b1101101) $display("error1");
		number = 4'dx;
		#50
		if(out != 7'b1111001) $display("error2");
	end
endmodule
