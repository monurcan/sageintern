
module g_relational_param_generate;
	class A;
		rand int unsigned Latency;
		rand int unsigned Port_Width;
		rand bit Enable_Port;
		rand bit Signed_Unsigned;
		rand int unsigned relational_Function;
		string rf[7] = {"A=B", "A!=B", "A>B", "A<B", "A>=B", "A<=B", "INVALID"};
		constraint C { Latency <= 256;
				Port_Width inside {[1:256]};
				relational_Function inside {[0:6]};
				}

		function void printPackage;
			int f = $fopen("g_relational_tb_parampkg.sv");
			$fdisplay(f, "package g_relational_tb_parampkg;");
			$fdisplay(f, "  parameter Latency = %0d;",Latency);
			$fdisplay(f, "  parameter Input_Width = %0d;",Port_Width);
			$fdisplay(f, "  parameter Signed_Unsigned = %0b;",Signed_Unsigned);
			$fdisplay(f, "  parameter Enable_Port = %0b;",Enable_Port);
			$fdisplay(f, "  parameter Comparison = \"%0s\";",rf[relational_Function]);
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
