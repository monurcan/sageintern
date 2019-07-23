
module g_constant_param_generate;
	class A;
		rand int signed Constant_Value;
		rand int unsigned Port_Width;
		constraint C { Port_Width inside {[1:256]}; }

		function void printPackage;
			int f = $fopen("g_constant_tb_parampkg.sv");
			$fdisplay(f, "package g_constant_tb_parampkg;");
			$fdisplay(f, "  parameter Constant_Value = %0d;",Constant_Value);
			$fdisplay(f, "  parameter Port_Width = %0d;",Port_Width);
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
