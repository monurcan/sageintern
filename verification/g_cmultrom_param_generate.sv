`include "p_memfuncs.sv"

module g_cmultrom_param_generate;
	class A;
		rand int unsigned Width, Latency;
		rand int signed Constant_Value;
		rand bit Enable_Port, Signed_Unsigned;

		constraint C { Latency <= 256; Width inside {[1:256]}; Constant_Value inside {[0:255]}; }

		function void printPackage;
			int f = $fopen("g_cmultrom_tb_parampkg.sv");
			string number;
			number.itoa(Constant_Value);
			$fdisplay(f, "package g_cmultrom_tb_parampkg;");
			$fdisplay(f, "  parameter Latency = %0d;",Latency);
			$fdisplay(f, "  parameter Width = %0d;",Width);
			$fdisplay(f, "  parameter Enable_Port = %0b;",Enable_Port);
			$fdisplay(f, "  parameter Signed_Unsigned = %0b;",Signed_Unsigned);
			$fdisplay(f, "  parameter Constant_Value = %0d;",Constant_Value);
			if(Constant_Value!=0) $fdisplay(f, "  parameter DATA_FILE = \"C:\\\\questasim64_10.4c\\\\examples\\\\cmultromtables\\\\g_cmultrom_data_",number,".txt\";");
			else $fdisplay(f, "  parameter DATA_FILE = \"All zeros\";");
			$fdisplay(f, "endpackage");
		endfunction
	endclass

	A a;
	initial begin
		a = new();
		a.randomize();
		a.printPackage();
	end
endmodule

