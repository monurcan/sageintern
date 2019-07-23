module muxAdvanced(
	input wire[15:0] alarmData, timeData, setData, wire showAlarm, showTime, alarmOn,
	output wire[15:0] display, wire soundAlarm
);
	wire[0:15] display0;
	wire display1;
	mux16 mux0(alarmData, setData, showAlarm, display0);
	mux16 mux1(timeData, display0, showTime, display);
	mux mux2(display1, 1'b0, alarmOn, soundAlarm);
	assign display1 = alarmData==timeData;
endmodule

module muxAdvanced_tb;
	reg[15:0] timeData, alarmData, setData;
	reg showAlarm, showTime, alarmOn;
	wire[15:0] display;
	wire soundAlarm;

	initial begin
		timeData = 0; alarmData = 11; setData = 19; showAlarm = 0; showTime = 1; alarmOn = 1;
		#50;
		alarmData = 65; setData = 19; showAlarm = 0; showTime = 1; alarmOn = 0;
		#50;
		alarmData = 65; setData = 19; showAlarm = 0; showTime = 0; alarmOn = 0;
	end

	initial
		forever begin #1; timeData = timeData + 1; end

	muxAdvanced DUT(alarmData, timeData, setData, showAlarm, showTime, alarmOn, display, soundAlarm);
endmodule
