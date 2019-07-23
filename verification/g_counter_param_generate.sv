module g_counter_param_generate;
	class A;
		rand int unsigned Count_Limit;
		rand int unsigned Direction;
		rand int unsigned Width;
		rand int unsigned Step;
		rand int unsigned G_Initial_Value;
		rand bit Out_type;
		rand bit Reset_Port;
		rand bit Load_Port;
		rand bit Enable_Port;
		rand bit Free_or_Limited;
		constraint C { Count_Limit < 256; Width inside {[1:256]}; Direction < 3; Step < 1000; G_Initial_Value < 1000; G_Initial_Value < Count_Limit; }

		function void printPackage;
			int f = $fopen("g_counter_tb_parampkg.sv");
			$fdisplay(f, "package g_counter_tb_parampkg;");
			$fdisplay(f, "  parameter Count_Limit = %0d;",Count_Limit);
			$fdisplay(f, "  parameter Width = %0d;",Width);
			$fdisplay(f, "  parameter Direction = %0d;",Direction);
			$fdisplay(f, "  parameter G_Initial_Value = %0d;",G_Initial_Value);
			$fdisplay(f, "  parameter Step = %0d;",Step);
			$fdisplay(f, "  parameter Out_type = %0b;",Out_type);
			$fdisplay(f, "  parameter Reset_Port = %0b;",Reset_Port);
			$fdisplay(f, "  parameter Load_Port = %0b;",Load_Port);
			$fdisplay(f, "  parameter Enable_Port = %0b;",Enable_Port);
			$fdisplay(f, "  parameter Free_or_Limited = %0b;",Free_or_Limited);
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
