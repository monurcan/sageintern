

vlog -work work -vopt -sv -stats=none C:/questasim64_10.4c/examples/g_mux_param_generate.sv
vsim -voptargs=+acc -sv_seed random work.g_mux_param_generate
run -all
vlog -work work -vopt -sv -stats=none C:/questasim64_10.4c/examples/g_mux_tb_parampkg.sv
vlog -work work -vopt -sv -stats=none C:/questasim64_10.4c/examples/g_mux_tb.sv
vsim -voptargs=+acc -sv_seed random work.g_mux_tbench_top
add wave -position insertpoint sim:/g_mux_tbench_top/i_intf/*
run -all
wave zoom full
