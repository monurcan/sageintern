module control(
	input wire alarm, hour, minute, clk, rst_n,
	output reg showTime, loadTime, showAlarm, loadAlarm, incrHour, incrMinute
);
reg[2:0] STATE, STATE_NEXT;

localparam [2:0]
	SHOW_ALARM = 3'b000,
	ALARM_SET = 3'b001,
	SHOW_TIME = 3'b010,
	TIME_SET = 3'b011,
	INC_AL_HR = 3'b100,
	INC_TI_HR = 3'b101,
	INC_AL_MN = 3'b110,
	INC_TI_MN = 3'b111;

always @(posedge clk, posedge rst_n)
begin
    if(!rst_n)
        begin
		STATE <= SHOW_TIME;
        end
    else
        begin
		STATE <= STATE_NEXT;
        end
end

always @(posedge clk, negedge rst_n)
begin
	STATE_NEXT = STATE;
	showTime=0; loadTime=0; showAlarm=0; loadAlarm=0; incrHour=0; incrMinute=0;
	case(STATE)
		SHOW_TIME:
		begin
		showTime = 1'b1;
    	        if(alarm)
			STATE_NEXT = SHOW_ALARM;
		else if(!alarm && (hour ==1))
			STATE_NEXT = INC_TI_HR;
		else if(!alarm && (minute ==1))
			STATE_NEXT = INC_TI_MN;

		end
		TIME_SET:
		begin
		STATE_NEXT = SHOW_TIME;
		loadTime = 1'b1;
		end
		ALARM_SET:
		begin
		loadAlarm=1'b1;
		STATE_NEXT=SHOW_ALARM;
		end
		SHOW_ALARM:
		begin
		showAlarm = 1'b1;
		if(~alarm)
			STATE_NEXT=SHOW_TIME;
		else if(!(~alarm) && (minute==1))
			STATE_NEXT=INC_AL_MN;
		else if(!(~alarm) && (hour==1))
			STATE_NEXT=INC_AL_HR;
		end
		INC_AL_HR:
		begin
		incrHour = 1'b1;
		if(~hour) STATE_NEXT=ALARM_SET;
		end
		INC_TI_HR:
		begin
		incrHour = 1'b1;
		if(~hour) STATE_NEXT=TIME_SET;
		end
		INC_AL_MN:
		begin
		incrMinute = 1'b1;
		if(~minute) STATE_NEXT=ALARM_SET;
		end
		INC_TI_MN:
		begin
		incrMinute = 1'b1;
		if(~minute) STATE_NEXT=TIME_SET;
		end
    	endcase
end
endmodule
