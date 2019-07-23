module g_multiplier_param_generate;
	class A;
		rand int unsigned Latency;
		rand bit Signed_Unsigned;
		rand int unsigned A_Width;
		rand int unsigned B_Width;
		rand bit Enable_Port;
		constraint C { Latency <= 256; A_Width inside {[0:256]}; B_Width inside {[0:256]}; }

		function void printPackage;
			int f = $fopen("g_multiplier_tb_parampkg.sv");
			$fdisplay(f, "package g_multiplier_tb_parampkg;");
			$fdisplay(f, "  parameter Latency = %0d;",Latency);
			$fdisplay(f, "  parameter Signed_Unsigned = %0b;",Signed_Unsigned);
			$fdisplay(f, "  parameter A_Width = %0d;",A_Width);
			$fdisplay(f, "  parameter B_Width = %0d;",B_Width);
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
