`include "p_memfuncs.sv"

module k_floatfft
#(
	int TRANSFORM_LENGTH = 16
)
(
	input logic aclk, aresetn = 1,
	input logic[2*clogb2(TRANSFORM_LENGTH):0] s_axis_config_tdata,
	// SCALE_SCH|FWD/INV one channel => 1111111 0 gibi [2*n_of_stages=2*clogb2 TRANSFORM_LENGTH] 1
	// digerleri runtime degil opsiyonel zaten ama kolay runtime yapmak transformlengthi, maxa gore ram ayirion islem sayini dusuruon bi kontrollerdaki donguler

//	input s_axis_config_tvalid;
//	output s_axis_config_tready;
	input logic[63:0]s_axis_data_tdata,
	input logic s_axis_data_tvalid,
	output logic s_axis_data_tready,
//	input s_axis_data_tlast;

	output logic[63:0]m_axis_data_tdata,
//	output [15:0]m_axis_data_tuser;
	output logic m_axis_data_tvalid,
	input logic m_axis_data_tready,
	output logic m_axis_data_tlast

//	output [0:0]m_axis_status_tdata;
//	output m_axis_status_tvalid;
//	input m_axis_status_tready;

//	output event_frame_started;
//	output event_tlast_unexpected;
//	output event_tlast_missing;
//	output event_fft_overflow;
//	output event_status_channel_halt;
//	output event_data_in_channel_halt;
//	output event_data_out_channel_halt;
);
	function logic[63:0] conjugateifReverse(logic[63:0] in, logic fwd_inv);
		conjugateifReverse[62:0] = in[62:0];
		conjugateifReverse[63] = (fwd_inv==1) ? in[63] : !in[63];
	endfunction

	wire[63:0] out0, out1, mult0_in1, mult1_in1, data0, data1, rom_out;
	wire sel0, sel1, sel2, en0, en1, rst0, rst1;
	wire[(clogb2(TRANSFORM_LENGTH)-1):0] addr0, addr1;
	wire[(clogb2(TRANSFORM_LENGTH)-2):0] rom_addr;
	wire[1:0] scaling;

	k_floatbutterfly butterfly(.in0(out0), .in1(out1), .twiddle(conjugateifReverse(rom_out, s_axis_config_tdata[0])), .scaling(scaling), .out0(mult0_in1), .out1(mult1_in1));

	g_mux#(.Input_Width(64), .Input_Ports(2), .Enable_Port(0), .Latency(0))
		mux0(.CLK(aclk), .SEL(sel0), .SIGNALS({s_axis_data_tdata, mult0_in1}), .MUXOUT(data0), .EN(1'b1));
	g_mux#(.Input_Width(64), .Input_Ports(2), .Enable_Port(0), .Latency(0))
		mux1(.CLK(aclk), .SEL(sel1), .SIGNALS({s_axis_data_tdata, mult1_in1}), .MUXOUT(data1), .EN(1'b1));
	g_mux#(.Input_Width(64), .Input_Ports(2), .Enable_Port(0), .Latency(0))
		mux2(.CLK(aclk), .SEL(sel2), .SIGNALS({out0, out1}), .MUXOUT(m_axis_data_tdata), .EN(1'b1));

	g_truedpram#(.RAM_WIDTH(64), .RAM_DEPTH(TRANSFORM_LENGTH), .Two_CLK(0), .Reset_Port_A(1), .Reset_Port_B(1), .Enable_Port_A(0), .Enable_Port_B(0), .Latency_A(1), .Latency_B(1))
		dp_ram(.CLK_A(aclk), .ADDR_A(addr0), .ADDR_B(addr1), .DATA_A(data0), .DATA_B(data1), .WR_EN_A(en0), .WR_EN_B(en1), .DOUT_A(out0), .DOUT_B(out1), .RST_A(rst0), .RST_B(rst1));

	g_rom#(.ROM_WIDTH(64), .ROM_DEPTH(TRANSFORM_LENGTH/2), .DATA_FILE("C:\\questasim64_10.4c\\examples\\fft_twiddlefactors_rom.txt"), .Enable_Port(0), .Latency(0))
		rom(.CLK(aclk), .ADDR(rom_addr), .DOUT(rom_out));

	k_controller#(.TRANSFORM_LENGTH(TRANSFORM_LENGTH)) controller(.scale_sch(s_axis_config_tdata[2*clogb2(TRANSFORM_LENGTH):1]), .*);

endmodule
