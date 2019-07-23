module g_barrelshift_param_generate;
	class A;
		rand int unsigned Latency;
		rand int unsigned A_Width;
		rand int unsigned Direction;
		rand bit Enable_Port;
		constraint C { Latency <= 256; A_Width inside {[0:256]}; Direction < 6; }

		function void printPackage;
			int f = $fopen("g_barrelshift_tb_parampkg.sv");
			$fdisplay(f, "package g_barrelshift_tb_parampkg;");
			$fdisplay(f, "  parameter Latency = %0d;",Latency);
			$fdisplay(f, "  parameter A_Width = %0d;",A_Width);
			$fdisplay(f, "  parameter Direction = %0d;",Direction);
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
