module g_leadingdet_param_generate;
	class A;
		rand int unsigned A_Width, Latency;
		rand bit Detect_from, Enable_Port, Detect_Value;
		constraint C { Latency <= 256; A_Width inside {[0:256]}; }

		function void printPackage;
			int f = $fopen("g_leadingdet_tb_parampkg.sv");
			$fdisplay(f, "package g_leadingdet_tb_parampkg;");
			$fdisplay(f, "  parameter A_Width = %0d;",A_Width);
			$fdisplay(f, "  parameter Latency = %0d;",Latency);
			$fdisplay(f, "  parameter Detect_from = %0d;",Detect_from);
			$fdisplay(f, "  parameter Detect_Value = %0d;",Detect_Value);
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
