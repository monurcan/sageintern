onerror {resume}
quietly virtual signal -install /k_float4fft_tb/FFT_inst0 { /k_float4fft_tb/FFT_inst0/rom_out[63:32]} rom_out_im
quietly virtual signal -install /k_float4fft_tb/FFT_inst0 { /k_float4fft_tb/FFT_inst0/rom_out[31:0]} rom_out_re
quietly virtual signal -install /k_float4fft_tb/FFT_inst0 { /k_float4fft_tb/FFT_inst0/data0[63:32]} data0_im
quietly virtual signal -install /k_float4fft_tb/FFT_inst0 { /k_float4fft_tb/FFT_inst0/data0[31:0]} data0_re
quietly virtual signal -install /k_float4fft_tb/FFT_inst0 { /k_float4fft_tb/FFT_inst0/data1[63:32]} data_im
quietly virtual signal -install /k_float4fft_tb/FFT_inst0 { /k_float4fft_tb/FFT_inst0/data1[31:0]} data1_im
quietly virtual signal -install /k_float4fft_tb/FFT_inst0 { /k_float4fft_tb/FFT_inst0/data1[31:0]} data1_re
quietly virtual signal -install /k_float4fft_tb/FFT_inst0 { /k_float4fft_tb/FFT_inst0/mult1_in1[63:32]} mult1_in1_im
quietly virtual signal -install /k_float4fft_tb/FFT_inst0 { /k_float4fft_tb/FFT_inst0/mult1_in1[31:0]} mult1_in1_re
quietly virtual signal -install /k_float4fft_tb/FFT_inst0 { /k_float4fft_tb/FFT_inst0/s_axis_data_tdata[63:32]} s_axis_data_tdata_im
quietly virtual signal -install /k_float4fft_tb/FFT_inst0 { /k_float4fft_tb/FFT_inst0/s_axis_data_tdata[31:0]} s_axis_data_tdata_im001
quietly virtual signal -install /k_float4fft_tb/FFT_inst0 { /k_float4fft_tb/FFT_inst0/s_axis_data_tdata[31:0]} s_axis_data_tdata_re
quietly virtual function -install /k_float4fft_tb/FFT_inst0 -env /k_float4fft_tb { &{/k_float4fft_tb/FFT_inst0/m_axis_data_tdata[63], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[62], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[61], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[60], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[59], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[58], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[57], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[56], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[55], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[54], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[53], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[52], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[51], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[50], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[49], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[48], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[47], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[46], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[45], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[44], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[43], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[42], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[41], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[40], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[39], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[38], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[37], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[36], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[35], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[34], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[33], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[32] }} m_axis_data_tdata_im
quietly virtual function -install /k_float4fft_tb/FFT_inst0 -env /k_float4fft_tb { &{/k_float4fft_tb/FFT_inst0/m_axis_data_tdata[31], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[30], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[29], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[28], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[27], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[26], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[25], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[24], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[23], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[22], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[21], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[20], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[19], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[18], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[17], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[16], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[15], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[14], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[13], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[12], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[11], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[10], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[9], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[8], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[7], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[6], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[5], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[4], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[3], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[2], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[1], /k_float4fft_tb/FFT_inst0/m_axis_data_tdata[0] }} m_axis_data_tdata_re
quietly WaveActivateNextPane {} 0
add wave -noupdate /k_float4fft_tb/FFT_inst0/aclk
add wave -noupdate /k_float4fft_tb/FFT_inst0/s_axis_config_tdata
add wave -noupdate -color red -format Analog-Interpolated -height 92 -max 1065349999.9999999 -min -1264860000.0 -radix float32 -radixenum symbolic -radixshowbase 0 /k_float4fft_tb/FFT_inst0/s_axis_data_tdata_re
add wave -noupdate /k_float4fft_tb/FFT_inst0/s_axis_data_tready
add wave -noupdate -color {royal blue} -format Analog-Step -height 139 -max 1133281248.0 -min -1274019840.0 -radix float32 -radixshowbase 0 /k_float4fft_tb/FFT_inst0/m_axis_data_tdata_im
add wave -noupdate -color {royal blue} -format Analog-Step -height 171 -max 1136806265.0000002 -min -1270874112.0 -radix float32 -radixshowbase 0 /k_float4fft_tb/FFT_inst0/m_axis_data_tdata_re
add wave -noupdate /k_float4fft_tb/m_axis_data_tready
add wave -noupdate /k_float4fft_tb/FFT_inst0/m_axis_data_tvalid
add wave -noupdate /k_float4fft_tb/FFT_inst0/m_axis_data_tlast
add wave -noupdate -radix float32 /k_float4fft_tb/FFT_inst0/s_axis_data_tdata_im
add wave -noupdate /k_float4fft_tb/FFT_inst0/out0
add wave -noupdate /k_float4fft_tb/FFT_inst0/out1
add wave -noupdate /k_float4fft_tb/FFT_inst0/mult0_in1
add wave -noupdate -radix float32 /k_float4fft_tb/FFT_inst0/mult1_in1_im
add wave -noupdate -radix float32 /k_float4fft_tb/FFT_inst0/mult1_in1_re
add wave -noupdate -radix float32 /k_float4fft_tb/FFT_inst0/data0_im
add wave -noupdate -radix float32 /k_float4fft_tb/FFT_inst0/data0_re
add wave -noupdate -label /k_float4fft_tb/FFT_inst0/data1_im -radix float32 /k_float4fft_tb/FFT_inst0/data_im
add wave -noupdate -radix float32 /k_float4fft_tb/FFT_inst0/data1_re
add wave -noupdate -radix float32 /k_float4fft_tb/FFT_inst0/rom_out_im
add wave -noupdate -radix float32 /k_float4fft_tb/FFT_inst0/rom_out_re
add wave -noupdate /k_float4fft_tb/FFT_inst0/sel0
add wave -noupdate /k_float4fft_tb/FFT_inst0/sel1
add wave -noupdate /k_float4fft_tb/FFT_inst0/sel2
add wave -noupdate /k_float4fft_tb/FFT_inst0/en0
add wave -noupdate /k_float4fft_tb/FFT_inst0/en1
add wave -noupdate /k_float4fft_tb/FFT_inst0/rst0
add wave -noupdate /k_float4fft_tb/FFT_inst0/rst1
add wave -noupdate /k_float4fft_tb/FFT_inst0/addr0
add wave -noupdate /k_float4fft_tb/FFT_inst0/addr1
add wave -noupdate /k_float4fft_tb/FFT_inst0/rom_addr
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {132475 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 278
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {116781 ns} {142117 ns}
