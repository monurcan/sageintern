module g_addshiftreg_param_generate;
	class A;
		rand int unsigned Latency;
		rand int unsigned Width;
		rand bit Enable_Port;

		constraint C { Latency inside {[2:1024]}; Width inside {[1:256]}; }

		function void printPackage;
			int f = $fopen("g_addshiftreg_tb_parampkg.sv");
			$fdisplay(f, "package g_addshiftreg_tb_parampkg;");
			$fdisplay(f, "  parameter Latency = %0d;",Latency);
			$fdisplay(f, "  parameter Width = %0d;",Width);
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
