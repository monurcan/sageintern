module digitalClock(
	input wire showAlarmIn, minutesIn, hoursIn, enAlarmIn, sysclk, reset,
	output wire soundAlarm, wire[27:0] disp7Seg
);
	wire showTime, loadTime, loadAlarm, incrHour, incrMinute;
	wire[15:0] setData, alarmData, timeData;
	wire oneMinute, halfSecond;
	control Control(showAlarmIn, hoursIn, minutesIn, sysclk, !reset, showTime, loadTime, showAlarm, loadAlarm, incrHour, incrMinute);
	time_set TimeSet(timeData, alarmData, halfSecond, showTime, showAlarm, incrHour, incrMinute, sysclk, !reset,setData);
	muxAdvanced7Segment ddrv(alarmData, timeData, setData, showAlarm, showTime, enAlarmIn, disp7Seg, soundAlarm);
	time_count TimeCount(setData,oneMinute,loadTime,sysclk,!reset,timeData);
	alarmReg alarmRegister(setData, loadAlarm, !reset, sysclk, alarmData);
	pulsegen pulseGen(!reset,sysclk, oneMinute, halfSecond);
endmodule

module digitalClock_tb;
	reg sysclk=0, reset=1, showAlarm, minutesIn, hoursIn, enAlarmIn;
	wire soundAlarm;
	wire[27:0] disp7Seg;

	initial
		forever #1 sysclk=~sysclk;
	
	initial begin
		#5 reset=0;
		showAlarm = 0; minutesIn=0; hoursIn=0; enAlarmIn=1;//bunu toggle ypican!
		#100
		showAlarm = 1; minutesIn=0; hoursIn=1; enAlarmIn=1;
		#15
		showAlarm = 0; minutesIn=0; hoursIn=0; enAlarmIn=1;
	end

	digitalClock DUT(showAlarm, minutesIn, hoursIn, enAlarmIn, sysclk, reset, soundAlarm, disp7Seg);
endmodule
