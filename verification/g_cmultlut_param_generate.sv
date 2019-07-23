module g_cmultlut_param_generate;
	class A;
		rand int unsigned Latency;
		rand bit Signed_Unsigned;
		rand int unsigned A_Width;
		rand int signed Constant_Value;
		rand bit Enable_Port;
		rand bit Reset_Port;
		constraint C { Latency <= 256; A_Width inside {[0:256]}; Constant_Value inside {[0:255]}; Enable_Port == 0; }

		function void printPackage;
			int f = $fopen("g_cmultlut_tb_parampkg.sv");
			$fdisplay(f, "package g_cmultlut_tb_parampkg;");
			$fdisplay(f, "  parameter Latency = %0d;",Latency);
			$fdisplay(f, "  parameter Signed_Unsigned = %0b;",Signed_Unsigned);
			$fdisplay(f, "  parameter A_Width = %0d;",A_Width);
			$fdisplay(f, "  parameter Constant_Value = %0d;",Constant_Value);
			$fdisplay(f, "  parameter Enable_Port = %0b;",Enable_Port);
			$fdisplay(f, "  parameter Reset_Port = %0b;",Reset_Port);
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
