module alarmReg(
	input wire[15:0] setData, wire loadAlarm, rst_n, clk,
	output reg[15:0] alarmData
);
	wire[15:0] muxout;
	mux16 mux(setData,alarmData,loadAlarm,muxout);

	always@(posedge clk, negedge rst_n) begin
		if(rst_n== 1'b0)
			alarmData <= 0;
		else
			alarmData <= muxout;
	end
endmodule

module alarmReg_tb;
	wire[15:0] setData;
	wire loadAlarm, rst_n;
	reg clk;
	wire[15:0] alarmData;
	alarmReg DUT(setData, loadAlarm, rst_n, clk, alarmData);
	initial begin
		clk = 0;
		forever begin #1; clk = clk + 1; end
	end
endmodule
