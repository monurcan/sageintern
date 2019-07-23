module encoder16(
	input wire[15:0] number,
	output wire[27:0] out
);
	encoder encoder0(number[3:0], out[6:0]);
	encoder encoder1(number[7:4], out[13:7]);
	encoder encoder2(number[11:8], out[20:14]);
	encoder encoder3(number[15:12], out[27:21]);
endmodule

module encoder16_test();
	wire[27:0] out;
	reg[15:0] number;
	encoder16 DUT(number,out);

	initial begin
		number = 16'b0101_0101_0001_0011;
		#50
		if(out != 28'b1101101110110100001101001111) $display("error1");
		number = 16'b0001_000x_0000_0010;
		#50
		if(out != 28'b0000110_1111001_0111111_1011011) $display("error2");
	end
endmodule
