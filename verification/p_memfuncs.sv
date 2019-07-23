
function int clogb2(int depth);
	automatic int v_temp = depth, v_ret_val = 0;

	while(v_temp > 1) begin
		v_ret_val = v_ret_val + 1;
		v_temp = v_temp / 2;
	end;

	if((2**v_ret_val) == depth)
		return v_ret_val;
	else
		return v_ret_val + 1;
endfunction
