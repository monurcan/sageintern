module g_adsub_param_generate;
	class A;
		rand int unsigned Operation;
		rand int unsigned Latency;
		rand bit Signed_Unsigned;
		rand int unsigned Width;
		rand bit Reset_Port;
		rand bit Carry_In_Port;
		rand bit Carry_Out_Port;
		rand bit Enable_Port;
		constraint C { Operation <= 3; Latency <= 256; 1 <= Width && Width <= 256; }

		function void printPackage;
			int f = $fopen("g_addsub_tb_parampkg.sv");
			$fdisplay(f, "package g_addsub_tb_parampkg;");
			$fdisplay(f, "  parameter Operation = %0d;",Operation);
			$fdisplay(f, "  parameter Latency = %0d;",Latency);
			$fdisplay(f, "  parameter Signed_Unsigned = %0b;",Signed_Unsigned);
			$fdisplay(f, "  parameter Width = %0d;",Width);
			$fdisplay(f, "  parameter Reset_Port = %0b;",Reset_Port);
			$fdisplay(f, "  parameter Carry_In_Port = %0b;",Carry_In_Port);
			$fdisplay(f, "  parameter Carry_Out_Port = %0b;",Carry_Out_Port);
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
