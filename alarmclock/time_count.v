module time_count(
	input wire[15:0] setData, wire oneMinute, loadTime, clk, rst_n,
	output reg[15:0] timeData
);
	wire[15:0] muxout;
	mux16 mux(setData,timeData,loadTime,muxout);

	always@(posedge clk, negedge rst_n) begin
		if(rst_n== 1'b0)
			timeData <= 0;
		else
			timeData <= muxout;
	end
	always@(clk)
		if(oneMinute==1'b1 && !loadTime) 
			casex(muxout)
				16'h2359: timeData <= 16'h0;
				16'h?959: timeData <= {muxout[15:12]+1,12'h0};
				16'h??59: begin
					timeData[15:12] <= muxout[15:12];
					timeData[11:0] <= {muxout[11:8]+1,8'h0};
				end
				16'h???9: begin
					timeData[15:8] <= muxout[15:8];
					timeData[7:0] <= {muxout[7:4]+1,4'h0};
				end
				default: timeData <= muxout+1;
			endcase
endmodule

module time_count_tb;
	reg clk=0, rst_n=1, loadTime;
	reg[15:0] setData;
	wire oneMinute, halfSecond;
	wire[15:0] timeData;
	initial
		forever #1 clk = !clk;
	initial begin
		loadTime = 1; setData = 16'h0107;
		#5;
		loadTime = 0;
	end
	pulsegen minutes(rst_n, clk, oneMinute, halfSecond);

	time_count DUT(setData, oneMinute, loadTime, clk, rst_n, timeData);
endmodule
