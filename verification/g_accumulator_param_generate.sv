module g_accumulator_param_generate;
	class A;
		rand bit Operation;
		rand int unsigned Latency;
		rand bit Signed_Unsigned;
		rand int unsigned Width;
		rand bit Reset_Port;
		rand bit Reset_Bypass;
		rand bit Enable_Port;
		constraint C { Operation <= 3; Latency <= 256; Width inside {[1:256]}; }

		function void printPackage;
			int f = $fopen("g_accumulator_tb_parampkg.sv");
			$fdisplay(f, "package g_accumulator_tb_parampkg;");
			$fdisplay(f, "  parameter Operation = %1b;",Operation);
			$fdisplay(f, "  parameter Latency = %0d;",Latency);
			$fdisplay(f, "  parameter Signed_Unsigned = %0b;",Signed_Unsigned);
			$fdisplay(f, "  parameter Width = %0d;",Width);
			$fdisplay(f, "  parameter Reset_Port = %0b;",Reset_Port);
			$fdisplay(f, "  parameter Reset_Bypass = %0b;",Reset_Bypass);
			$fdisplay(f, "  parameter Enable_Port = %0b;",Enable_Port);
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
