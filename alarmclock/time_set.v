
module time_set(
	input wire[15:0] timeData, alarmData, wire halfSecond, showTime, showAlarm, incrHour, incrMinute, clk, rst_n,
	output reg[15:0] setData
);
	wire[15:0] muxout, muxout1, muxout2;
	mux16 mux1(timeData,setData,showTime,muxout1);
	mux16 mux2(alarmData,setData,showAlarm,muxout2);
	mux16 mux3(muxout1,muxout2,showTime,muxout);

	always@(posedge clk, negedge rst_n) begin
		if(rst_n== 1'b0)
			setData <= 0;
		else
			setData <= muxout;
	end

	always@(clk)
		if(halfSecond==1'b1 && !showTime && !showAlarm)
			if(incrMinute)
				casex(muxout[7:0])
					8'h59: setData[7:0] <= 8'h0;
					8'hx9: setData[7:0] <= {muxout[7:4]+1,4'h0};
					default: setData[7:0] <= muxout+1;
				endcase
			else if(incrHour)
				casex(muxout[15:8])
					8'h23: setData[15:8] <= 8'h0;
					8'hx9: setData[15:8] <= {muxout[15:12]+1,4'h0};
					default: setData[15:8] <= muxout[15:8]+1;
				endcase
endmodule

module time_set_tb;
	reg clk=0, rst_n=1,showTime=1,showAlarm=0,incrHour=0,incrMinute=0;
	reg[15:0] timeData=16'h1231, alarmData=16'h1130;
	wire oneMinute, halfSecond;
	wire[15:0] setData;
	initial
		forever #1 clk = !clk;
	initial begin
		#10
		showTime=0;
		#50;
		incrHour=1;
		#50
		incrHour=0;
		#50
		showAlarm=1; showTime=0;
		#1
		showAlarm=0;
		#50
		incrMinute=1;
		#1000
		rst_n=0;
	end

	pulsegen seconds(rst_n, clk, oneMinute, halfSecond);
	time_set DUT(timeData, alarmData, halfSecond, showTime, showAlarm, incrHour, incrMinute, clk, rst_n, setData);
endmodule