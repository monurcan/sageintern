`timescale 1ns/1ns
`define STAGE_NO 10

module k_fixedfft_tb();
logic SCLK;

initial SCLK = 0;
always #5     SCLK = ~SCLK;

reg     signed  [15:0]  data_men[0:(2**`STAGE_NO-1)];
initial begin
    $readmemb("C:/questasim64_10.4c/examples/sin_data.txt",data_men);
end

//-------input-----------//
reg     [2*`STAGE_NO:0]  s_axis_config_tdata;
reg aresetn;
reg     s_axis_config_tvalid;
reg     signed  [15:0]  s_axis_data_tdata;
reg     s_axis_data_tvalid;
reg     s_axis_data_tlast;
reg     m_axis_data_tready;
//reg		m_axis_status_tready;
//-------output---------//
wire    s_axis_config_tready;
wire    s_axis_data_tready;
wire    [15:0]  m_axis_data_tdata;
wire	[15:0]	m_axis_data_tuser;
wire    m_axis_data_tvalid;
wire    m_axis_data_tlast;
//wire	[7:0]	m_axis_status_tdata;
//wire	m_axis_status_tvalid;
wire    event_frame_started;
wire    event_tlast_unexpected;
wire    event_tlast_missing;
//wire	event_fft_overflow;
wire    event_status_channel_halt;
wire    event_data_in_channel_halt;
wire    event_data_out_channel_halt;
//------------------------------//
k_fixedfft
#(
	.TRANSFORM_LENGTH(2**`STAGE_NO)
) FFT_inst0
(
        .aclk(SCLK),
	.aresetn (aresetn),
        .s_axis_config_tdata        (s_axis_config_tdata),
//        .s_axis_config_tvalid       (s_axis_config_tvalid),
//        .s_axis_config_tready       (s_axis_config_tready),
        .s_axis_data_tdata          (s_axis_data_tdata),
        .s_axis_data_tvalid         (s_axis_data_tvalid),
        .s_axis_data_tready         (s_axis_data_tready),
//        .s_axis_data_tlast          (s_axis_data_tlast),
        .m_axis_data_tdata          (m_axis_data_tdata),
//        .m_axis_data_tuser          (m_axis_data_tuser),
        .m_axis_data_tvalid         (m_axis_data_tvalid),
        .m_axis_data_tready         (m_axis_data_tready),
        .m_axis_data_tlast          (m_axis_data_tlast)
////        .m_axis_status_tdata        (m_axis_status_tdata),
////        .m_axis_status_tvalid       (m_axis_status_tvalid),
////        .m_axis_status_tready       (m_axis_status_tready),
//        .event_frame_started        (event_frame_started),
//        .event_tlast_unexpected     (event_tlast_unexpected),
//        .event_tlast_missing        (event_tlast_missing),
////        .event_fft_overflow         (event_fft_overflow),
//        .event_status_channel_halt  (event_status_channel_halt),
//        .event_data_in_channel_halt (event_data_in_channel_halt),
//        .event_data_out_channel_halt(event_data_out_channel_halt)
);
//===================================//
integer i = 0;
int f = $fopen("C:/Users/Mehmet Onurcan KAYA/Documents/MATLAB/exp/fft_res_vec.m");

initial begin
    s_axis_config_tdata = 0;
    s_axis_config_tvalid = 0;
    s_axis_data_tdata = 0;
    s_axis_data_tvalid = 0;
    m_axis_data_tready = 0;
	aresetn=0;
    #145;
	aresetn=1;
    s_axis_config_tvalid = 1;
    s_axis_config_tdata = {{10{2'b01}}, 1'b1};

//    s_axis_data_tdata = 15'd0;
    s_axis_data_tvalid = 0;

    begin
        for (i=0;i<2**`STAGE_NO;i=i+1) begin
            s_axis_data_tvalid <= 1;
            s_axis_data_tdata <= data_men[i];
            #10;
        end
    end
    #10
    s_axis_data_tdata = 15'd0;
    s_axis_data_tvalid = 0;
    #520000
    m_axis_data_tready = 1;
#15

//	$display("fft_res = [");
	$fdisplay(f, "fft_res = [");
	for (i=0;i<2**`STAGE_NO;i=i+1) begin
		//$display("'%b';",m_axis_data_tdata);
		$fdisplay(f, "'%b';",m_axis_data_tdata);
            #10;
        end
//	$display("];");
	$fdisplay(f,"];");
    m_axis_data_tready = 0;
  	#200
    $stop;
end

//initial begin
//        for (i=0;i<512;i=i+1) begin
//end

endmodule
