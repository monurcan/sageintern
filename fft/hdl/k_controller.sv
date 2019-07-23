`include "p_memfuncs.sv"

module k_controller
#(
	int TRANSFORM_LENGTH = 16
)
(
	input logic aclk, aresetn=1, s_axis_data_tvalid,
	input logic[(2*clogb2(TRANSFORM_LENGTH)-1):0] scale_sch='0,
	output logic sel0=0, sel1=0, sel2=0, en0, en1, rst0, rst1,
		logic[(clogb2(TRANSFORM_LENGTH)-1):0] addr0=0, addr1=0,
		logic[(clogb2(TRANSFORM_LENGTH)-2):0] rom_addr=0,
		logic[1:0] scaling,

	output logic m_axis_data_tvalid=0,
	input logic m_axis_data_tready=0,
	output logic m_axis_data_tlast=0,
	output logic s_axis_data_tready=1
);

function logic[(clogb2(TRANSFORM_LENGTH)-1):0] reverse_bits(input logic[(clogb2(TRANSFORM_LENGTH)-1):0] in);
	logic[(clogb2(TRANSFORM_LENGTH)-1):0] res;

	for(int i=0; i<clogb2(TRANSFORM_LENGTH); i++)
		res[i] = in[clogb2(TRANSFORM_LENGTH) - 1 - i];

	return res;
endfunction

typedef enum logic[2:0] {RST, SAMPLE, READ, WRITE, IDLE, RESULTS} state_;
state_ STATE, NEXT_STATE=RST;

logic[(clogb2(TRANSFORM_LENGTH/2)-1):0] _element = 0, _set = 0;
logic[(clogb2(clogb2(TRANSFORM_LENGTH))-1):0] _stage = 0;

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
		sel0 <= 0; sel1 <= 0;
		en0 <= 1; en1 <= 0; // read using first port
		addr0 <= reverse_bits(reverse_bits(addr0)+1);
		if(addr0 == (TRANSFORM_LENGTH-1)) begin
			s_axis_data_tready <= 0;
			en0 <= 0; en1 <= 0;
			
			rom_addr <= 0;
			addr0 <= 0;
			addr1 <= 1;

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
			sel2 <= 1;
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
			en0 <= 0;
			en1 <= 0;
			addr0 <= 0;
			addr1 <= 0;
			rom_addr <= 0;
			m_axis_data_tvalid<=0;
			m_axis_data_tlast=0;
			if(s_axis_data_tvalid==1) begin rst0 <= 0; rst1 <= 0; en0 <= 1; en1 <= 0; STATE <= SAMPLE; NEXT_STATE <= SAMPLE; end
		end
		READ: begin
			s_axis_data_tready <= 0;
			//$display("read %t", $time);
			en0 <= 0; en1 <= 0;
			rom_addr <= (_element << (clogb2(TRANSFORM_LENGTH)-1-_stage));
			//rom_addr[clogb2(TRANSFORM_LENGTH)-1] <= fwd_inv;
			addr0 <= 2**(_stage+1) * _set + _element;
			addr1 <= 2**(_stage+1) * _set + _element + 2**_stage;

			NEXT_STATE <= WRITE;
		end
		WRITE:begin
			s_axis_data_tready <= 0;
			//$display("write %t", $time);
			en0 <= 1; en1 <= 1;
			sel0 <= 1; sel1 <= 1;
			NEXT_STATE <= READ;

			if(_element == (2**_stage - 1))
				if(_set == (TRANSFORM_LENGTH / 2**(_stage+1) - 1))
					if(_stage == (clogb2(TRANSFORM_LENGTH) - 1)) begin
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
			addr0 <= 0; addr1 <= 0;
			s_axis_data_tready <= 1;
			en0 <= 0; en1 <= 0; sel2<='x;
			if(m_axis_data_tvalid && m_axis_data_tready) begin
				STATE <= RESULTS;
				NEXT_STATE <= RESULTS;
				addr1 <= 0;
				sel2 <= 1;
			end
			if(s_axis_data_tvalid==1) begin rst0 <= 0; rst1 <= 0; en0 <= 1; en1 <= 0; STATE <= SAMPLE; NEXT_STATE <= SAMPLE; end
		end
		endcase
end

endmodule
