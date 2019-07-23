vlog -work work -vopt -sv -stats=none C:/questasim64_10.4c/examples/g_inverter_param_generate.sv
vsim -voptargs=+acc -sv_seed random work.g_inverter_param_generate
run -all
vlog -work work -vopt -sv -stats=none C:/questasim64_10.4c/examples/g_inverter_tb_parampkg.sv
vlog -work work -vopt -sv -stats=none C:/questasim64_10.4c/examples/g_inverter_tb.sv
vsim -voptargs=+acc -sv_seed random work.g_inverter_tbench_top
add wave -position insertpoint sim:/g_inverter_tbench_top/i_intf/*
run -all
wave zoom full
