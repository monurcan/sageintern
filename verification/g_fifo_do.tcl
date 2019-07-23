

vlog -work work -vopt -sv -stats=none C:/questasim64_10.4c/examples/g_fifo_param_generate.sv
vsim -voptargs=+acc -sv_seed random work.g_fifo_param_generate
run -all
vlog -work work -vopt -sv -stats=none C:/questasim64_10.4c/examples/g_fifo_tb_parampkg.sv
vlog -work work -vopt -sv -cover sbcet3 -stats=none C:/questasim64_10.4c/examples/g_fifo_tb.sv
vsim -voptargs=+acc -sv_seed random -coverage work.g_fifo_tbench_top
add wave -position insertpoint sim:/g_fifo_tbench_top/i_intf/*
run -all
wave zoom full
