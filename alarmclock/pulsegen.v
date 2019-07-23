module pulsegen(
	input wire rst_n, clk,
	output reg oneMinute, halfSecond
);
	reg[12:0] count;

	initial
		count = 13'd7680;

	always@(clk,rst_n) begin
		count = (count && rst_n) ? count - 1 : 13'd7679;
	end

	always@(count) begin
		oneMinute = (count == 0) ? 1 : 0;
		halfSecond = (count % 64) ? 0 : 1;
	end
endmodule