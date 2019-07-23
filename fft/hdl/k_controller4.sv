`include "p_memfuncs.sv"

module k_controller4
#(
	int TRANSFORM_LENGTH = 64
)
(
	input logic aclk, aresetn=1, s_axis_data_tvalid,
	input logic[(clogb2(TRANSFORM_LENGTH)-1):0] scale_sch='0,
	output logic sel0=0, sel1=0, sel2=0, sel3=0, sel4=0, en0, en1, en2, en3, rst0, rst1, rst2, rst3,
		logic[(clogb2(TRANSFORM_LENGTH)-1):0] addr0=0, addr1=0, addr2=0, addr3=0, 
		logic[(clogb2(TRANSFORM_LENGTH)-3):0] rom_addr0=0,
		logic[1:0] scaling,

	output logic m_axis_data_tvalid=0,
	input logic m_axis_data_tready=0,
	output logic m_axis_data_tlast=0,
	output logic s_axis_data_tready=1
);

function logic[(clogb2(TRANSFORM_LENGTH)-1):0] reverse_digits(input logic[(clogb2(TRANSFORM_LENGTH)-1):0] in);
//	logic[(clogb2(TRANSFORM_LENGTH)-1):0] res;
//
//	if(clogb2(TRANSFORM_LENGTH) % 2 == 1)
//		res[clogb2(TRANSFORM_LENGTH)-1] = in[0];
//
//	for(int i=0; i<(clogb2(TRANSFORM_LENGTH)/2); i++)
//			res[2*i+:2] = in[clogb2(TRANSFORM_LENGTH) - 2 - 2*i +: 2];
//		
//	return res;

logic[(clogb2(TRANSFORM_LENGTH)-1):0] res;

	for(int i=0; i<clogb2(TRANSFORM_LENGTH); i++)
		res[i] = in[clogb2(TRANSFORM_LENGTH) - 1 - i];

	return res;
endfunction

function logic[(clogb2(TRANSFORM_LENGTH)-1):0] inverse_reverse_digits(input logic[(clogb2(TRANSFORM_LENGTH)-1):0] in);
//	logic[(clogb2(TRANSFORM_LENGTH)-1):0] res;
//
//	if(clogb2(TRANSFORM_LENGTH) % 2 == 1) begin
//		res[0] = in[clogb2(TRANSFORM_LENGTH)-1];
//
//		for(int i=0; i<(clogb2(TRANSFORM_LENGTH)/2); i++)
//			res[(2*i+1)+:2] = in[clogb2(TRANSFORM_LENGTH) - 3 - 2*i +: 2];
//	end else
//		for(int i=0; i<(clogb2(TRANSFORM_LENGTH)/2); i++)
//			res[2*i+:2] = in[clogb2(TRANSFORM_LENGTH) - 2 - 2*i +: 2];
//		
//	return res;

logic[(clogb2(TRANSFORM_LENGTH)-1):0] res;

	for(int i=0; i<clogb2(TRANSFORM_LENGTH); i++)
		res[i] = in[clogb2(TRANSFORM_LENGTH) - 1 - i];

	return res;
endfunction

typedef enum logic[2:0] {RST, SAMPLE, READ, WRITE, IDLE, RESULTS} state_;
state_ STATE, NEXT_STATE=RST;

logic[(clogb2(TRANSFORM_LENGTH /4)-1):0] _element = 0, _set = 0;
logic[(clogb2(clogb2(TRANSFORM_LENGTH) /2)-1):0] _stage = 0;

assign scaling = scale_sch[2*_stage +: 2];

always @(posedge aclk, negedge aresetn)
begin 
if (!aresetn)
	STATE <= RST;
else begin
	STATE <= NEXT_STATE;
	case(STATE)
	SAMPLE: begin
		s_axis_data_tready <= 1;
		sel0 <= 0; sel1 <= 0; sel2 <= 0; sel3 <= 0;
		en0 <= 1; en1 <= 0; en2 <= 0; en3 <= 0; // read using first port
		addr0 <= reverse_digits(inverse_reverse_digits(addr0)+1);
		if(addr0 == (TRANSFORM_LENGTH-1)) begin
			s_axis_data_tready <= 0;
			en0 <= 0; en1 <= 0; en2 <= 0; en3 <= 0;
			
			rom_addr0 <= 0;
			addr0 <= 0;
			addr1 <= 1;
			addr2 <= 2;
			addr3 <= 3;

			m_axis_data_tlast <= 1;
			STATE <= READ;
		end
	end
	RESULTS: begin
		s_axis_data_tready <= 0;
		if(s_axis_data_tvalid)
			NEXT_STATE <= SAMPLE;
		else if(m_axis_data_tvalid && m_axis_data_tready) begin
			addr1 <= (addr1 + 1);
			sel4 <= 1; //  show results using port 2
			NEXT_STATE <= RESULTS;
//			if(addr1 == (TRANSFORM_LENGTH-1)) NEXT_STATE <= IDLE;
		end else begin
			NEXT_STATE <= IDLE;
		end
	end
	endcase
end
end

always @(STATE, s_axis_data_tvalid, m_axis_data_tready) begin
		//if(s_axis_data_tvalid==1) begin en0 <= 1; en1 <= 0; STATE <= SAMPLE; end
		case(STATE)
		RST: begin
			s_axis_data_tready <= 1;
			rst0 <= 1;
			rst1 <= 1;
			rst2 <= 1;
			rst3 <= 1;
			en0 <= 0;
			en1 <= 0;
			en2 <= 0;
			en3 <= 0;
			addr0 <= 0;
			addr1 <= 0;
			addr2 <= 0;
			addr3 <= 0;
			rom_addr0 <= 0;
			m_axis_data_tvalid<=0;
			m_axis_data_tlast=0;
			if(s_axis_data_tvalid==1) begin rst0 <= 0; rst1 <= 0; rst2 <= 0; rst3 <= 0; en0 <= 1; en1 <= 0; en2 <= 0; en3 <= 0; STATE <= SAMPLE; NEXT_STATE <= SAMPLE; end
		end
		READ: begin
			s_axis_data_tready <= 0;
			//$display("read %t", $time);
			en0 <= 0; en1 <= 0; en2 <= 0; en3 <= 0;
			rom_addr0 <= (_element << (clogb2(TRANSFORM_LENGTH)-1-_stage *2))/2; // l
			addr0 <= 4**(_stage+1) * _set + _element;
			addr1 <= 4**(_stage+1) * _set + _element + 4**_stage;
			addr2 <= 4**(_stage+1) * _set + _element + (4**_stage)*2;
			addr3 <= 4**(_stage+1) * _set + _element + (4**_stage)*3;

			NEXT_STATE <= WRITE;
		end
		WRITE:begin
			s_axis_data_tready <= 0;
			//$display("write %t", $time);
			en0 <= 1; en1 <= 1; en2 <= 1; en3 <= 1;
			sel0 <= 1; sel1 <= 1; sel2 <= 1; sel3 <= 1;
			NEXT_STATE <= READ;

			if(_element == (4**_stage - 1))
				if(_set == (TRANSFORM_LENGTH / 4**(_stage+1) - 1))
					if(_stage == (clogb2(TRANSFORM_LENGTH) /2 - 1)) begin
						m_axis_data_tvalid<=1;

						NEXT_STATE <= IDLE;
						_set  <= 0; _element <= 0; _stage <= 0;
						//$display("calc finished @%t", $time);
						//$stop;
					end else begin _stage <= _stage + 1; _set=0; _element<=0; end
				else begin _set <= _set+1; _element <= 0; end
			else _element <= _element+1;
		end
		IDLE: begin
			addr0 <= 0; addr1 <= 0; addr2 <= 0; addr3 <= 0;
			s_axis_data_tready <= 1;
			en0 <= 0; en1 <= 0; en2 <= 0; en3 <= 0; sel4<='x;
			if(m_axis_data_tvalid && m_axis_data_tready) begin
				STATE <= RESULTS;
				NEXT_STATE <= RESULTS;
				addr1 <= 0;
				sel4 <= 1;
			end
			if(s_axis_data_tvalid==1) begin rst0 <= 0; rst1 <= 0; rst2 <= 0; rst3 <= 0; en0 <= 1; en1 <= 0; en2 <= 0; en3 <= 0; STATE <= SAMPLE; NEXT_STATE <= SAMPLE; end
		end
		endcase
end

endmodule
