`include "p_memfuncs.sv"

module g_cmultrom_file_generate;
	function void printData1;
		int f;
		string number;
		logic signed[(g_cmultrom_tb_parampkg::Width+clogb2(g_cmultrom_tb_parampkg::Constant_Value)+1):0] res;

		for(int signed num = -252; num < 256; num++) begin
			number.itoa(num);
			f = $fopen({"cmultromtables/g_cmultrom_data_",number,".txt"}, "w");
			for(int i = 0; i < 256; i++) begin res = i*num; $fdisplay(f, "%b", res); end
		end
	endfunction
	
	function void printData2;
		int f;
		string number;
		logic signed[(g_cmultrom_tb_parampkg::Width+clogb2(g_cmultrom_tb_parampkg::Constant_Value)+1):0] res;

		for(int signed num = -255; num < -252; num++) begin
			number.itoa(num);
			f = $fopen({"cmultromtables/g_cmultrom_data_",number,".txt"}, "w");
			for(int i = 0; i < 256; i++) begin res = i*num; $fdisplay(f, "%b", res); end
		end
	endfunction

	initial begin
	// only once
	printData1(); // first only this
	//printData2(); // then only this
	end
endmodule
