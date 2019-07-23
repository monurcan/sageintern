`include "p_memfuncs.sv"

module k_fixed4fft
#(
	int TRANSFORM_LENGTH = 4
)
(
	input logic aclk, aresetn = 1,
	input logic[clogb2(TRANSFORM_LENGTH):0] s_axis_config_tdata,
	// SCALE_SCH|FWD/INV one channel => 1111111 0 gibi [2*n_of_stages=2*clogb2 TRANSFORM_LENGTH] 1
	// digerleri runtime degil opsiyonel zaten ama kolay runtime yapmak transformlengthi, maxa gore ram ayirion islem sayini dusuruon bi kontrollerdaki donguler

//	input s_axis_config_tvalid;
//	output s_axis_config_tready;
	input logic[15:0]s_axis_data_tdata,
	input logic s_axis_data_tvalid,
	output logic s_axis_data_tready,
//	input s_axis_data_tlast;

	output logic[15:0]m_axis_data_tdata,
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
	function logic[15:0] conjugateifReverse(logic[15:0] in, logic fwd_inv);
		conjugateifReverse[7:0] = in[7:0];
		conjugateifReverse[15:8] = (fwd_inv==1) ? in[15:8] : -in[15:8];
	endfunction

	wire[15:0] out0, out1, out2, out3, mult0_in1, mult1_in1, mult2_in1, mult3_in1, data0, data1, data2, data3, rom_out0, rom_out1, rom_out2;
	wire sel0, sel1, sel2, sel3, sel4, en0, en1, en2, en3, rst0, rst1, rst2, rst3;
	wire[(clogb2(TRANSFORM_LENGTH)-1):0] addr0, addr1, addr2, addr3;
	wire[(clogb2(TRANSFORM_LENGTH)-3):0] rom_addr0;
	wire[1:0] scaling;

	k_fixeddragonfly dragonfly(.in0(out0), .in1(out1), .in2(out2), .in3(out3), .twiddle0(conjugateifReverse(rom_out0, s_axis_config_tdata[0])), .scaling(scaling), .out0(mult0_in1), .out1(mult1_in1), .out2(mult2_in1), .out3(mult3_in1));

	g_mux#(.Input_Width(16), .Input_Ports(2), .Enable_Port(0), .Latency(0))
		mux0(.CLK(aclk), .SEL(sel0), .SIGNALS({s_axis_data_tdata, mult0_in1}), .MUXOUT(data0), .EN(1'b1));
	g_mux#(.Input_Width(16), .Input_Ports(2), .Enable_Port(0), .Latency(0))
		mux1(.CLK(aclk), .SEL(sel1), .SIGNALS({s_axis_data_tdata, mult1_in1}), .MUXOUT(data1), .EN(1'b1));
	g_mux#(.Input_Width(16), .Input_Ports(2), .Enable_Port(0), .Latency(0))
		mux2(.CLK(aclk), .SEL(sel2), .SIGNALS({s_axis_data_tdata, mult2_in1}), .MUXOUT(data2), .EN(1'b1));
	g_mux#(.Input_Width(16), .Input_Ports(2), .Enable_Port(0), .Latency(0))
		mux3(.CLK(aclk), .SEL(sel3), .SIGNALS({s_axis_data_tdata, mult3_in1}), .MUXOUT(data3), .EN(1'b1));
	g_mux#(.Input_Width(16), .Input_Ports(2), .Enable_Port(0), .Latency(0))
		mux4(.CLK(aclk), .SEL(sel4), .SIGNALS({out0, out1}), .MUXOUT(m_axis_data_tdata), .EN(1'b1));

	k_quadram#(.RAM_WIDTH(16), .RAM_DEPTH(TRANSFORM_LENGTH), .Enable_Port_A(0), .Enable_Port_B(0), .Enable_Port_C(0), .Enable_Port_D(0))
		dp_ram(.CLK_A(aclk), .ADDR_A(addr0), .ADDR_B(addr1), .ADDR_C(addr2), .ADDR_D(addr3), .DATA_A(data0), .DATA_B(data1), .DATA_C(data2), .DATA_D(data3), .WR_EN_A(en0), .WR_EN_B(en1), .WR_EN_C(en2), .WR_EN_D(en3), .DOUT_A(out0), .DOUT_B(out1), .DOUT_C(out2), .DOUT_D(out3), .RST_A(rst0), .RST_B(rst1), .RST_C(rst2), .RST_D(rst3));

	g_rom#(.ROM_WIDTH(16), .ROM_DEPTH(TRANSFORM_LENGTH/4), .DATA_FILE("C:\\questasim64_10.4c\\examples\\fft4_twiddlefactors_rom.txt"), .Enable_Port(0))
		rom(.CLK(aclk), .ADDR(rom_addr0), .DOUT(rom_out0));

	k_controller4#(.TRANSFORM_LENGTH(TRANSFORM_LENGTH)) controller(.scale_sch(s_axis_config_tdata[clogb2(TRANSFORM_LENGTH):1]), .*);

endmodule