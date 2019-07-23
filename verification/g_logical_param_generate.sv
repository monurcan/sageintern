
module g_logical_param_generate;
	class A;
		rand int unsigned Latency;
		rand int unsigned Port_Width;
		rand int unsigned Input_Ports;
		rand bit Enable_Port;
		typedef enum {AND, NAND, OR, NOR, XOR, XNOR, INVALID} lf;
		rand lf Logical_Function;
		constraint C { Latency <= 256;
				Input_Ports inside {[2:1024]};
				Port_Width inside {[1:256]};
				Logical_Function inside {[0:6]};
				}

		function void printPackage;
			int f = $fopen("g_logical_tb_parampkg.sv");
			$fdisplay(f, "package g_logical_tb_parampkg;");
			$fdisplay(f, "  parameter Latency = %0d;",Latency);
			$fdisplay(f, "  parameter Input_Width = %0d;",Port_Width);
			$fdisplay(f, "  parameter Input_Ports = %0d;",Input_Ports);
			$fdisplay(f, "  parameter Enable_Port = %0b;",Enable_Port);
			$fdisplay(f, "  parameter Logical_Function = \"%0s\";",Logical_Function.name());
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