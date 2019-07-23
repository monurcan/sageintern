vlog -work work -vopt -sv -stats=none C:/questasim64_10.4c/examples/g_register_param_generate.sv
vsim -voptargs=+acc -sv_seed random work.g_register_param_generate
run -all
vlog -work work -vopt -sv -stats=none C:/questasim64_10.4c/examples/g_register_tb_parampkg.sv
vlog -work work -vopt -sv -cover sbcet3 -stats=none C:/questasim64_10.4c/examples/g_register_tb.sv
vsim -voptargs=+acc -sv_seed random -coverage work.g_register_tbench_top
add wave -position insertpoint sim:/g_register_tbench_top/i_intf/*
run -all
wave zoom full
