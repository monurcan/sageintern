
module g_mux_param_generate;
	class A;
		rand int unsigned Latency;
		rand int unsigned Port_Width;
		rand int unsigned Input_Ports;
		rand bit Enable_Port;
		constraint C { Latency <= 256;
				Input_Ports inside {[0:256]};
				Port_Width inside {[1:256]};
				}

		function void printPackage;
			int f = $fopen("g_mux_tb_parampkg.sv");
			$fdisplay(f, "package g_mux_tb_parampkg;");
			$fdisplay(f, "  parameter Latency = %0d;",Latency);
			$fdisplay(f, "  parameter Input_Width = %0d;",Port_Width);
			$fdisplay(f, "  parameter Input_Ports = %0d;",Input_Ports);
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
