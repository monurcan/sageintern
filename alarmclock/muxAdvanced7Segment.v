
module muxAdvanced7Segment(
	input wire[15:0] alarmData, timeData, setData, wire showAlarm, showTime, alarmOn,
	output wire[27:0] display7Segment, wire soundAlarm
);
	wire[15:0] display;
	muxAdvanced mux(alarmData, timeData, setData, showAlarm, showTime, alarmOn, display, soundAlarm);
	encoder16 enc(display, display7Segment);
endmodule


module muxAdvanced7Segment_tb;
	reg[15:0] timeData, alarmData, setData;
	reg showAlarm, showTime, alarmOn;
	wire[27:0] display;
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

	muxAdvanced7Segment DUT(alarmData, timeData, setData, showAlarm, showTime, alarmOn, display, soundAlarm);
endmodule
