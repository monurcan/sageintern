
module g_inverter_param_generate;
	class A;
		rand int unsigned Latency;
		rand int unsigned Port_Width;
		rand bit Enable_Port;
		constraint C { Latency <= 256; 1 <= Port_Width && Port_Width <= 256; }

		function void printPackage;
			int f = $fopen("g_inverter_tb_parampkg.sv");
			$fdisplay(f, "package g_inverter_tb_parampkg;");
			$fdisplay(f, "  parameter Latency = %0d;",Latency);
			$fdisplay(f, "  parameter Port_Width = %0d;",Port_Width);
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