module g_register_param_generate;
	class A;
		rand int unsigned Initial_Value;
		rand int unsigned Width;
		rand bit Enable_Port, Reset_Port;

		constraint C { Initial_Value < 5000; Width inside {[1:256]}; }

		function void printPackage;
			int f = $fopen("g_register_tb_parampkg.sv");
			$fdisplay(f, "package g_register_tb_parampkg;");
			$fdisplay(f, "  parameter Initial_Value = %0d;",Initial_Value);
			$fdisplay(f, "  parameter Width = %0d;",Width);
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
