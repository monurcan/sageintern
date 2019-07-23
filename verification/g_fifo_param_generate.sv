module g_fifo_param_generate;
	class A;
		rand int unsigned Width, Depth, Almost_Empty_Treshold, Almost_Full_Treshold;
		rand bit Enable_Port, Reset_Port, Data_Count_Port, Almost_Empty_Port, Almost_Full_Port, FWFT;

		constraint C {
			solve Depth before Almost_Full_Treshold;
			Depth inside {[1:65536]};
			Almost_Full_Treshold < Depth;
			Almost_Empty_Treshold < Almost_Full_Treshold;
			Width inside {[1:256]};
			Enable_Port==0;
		}

		function void printPackage;
			int f = $fopen("g_fifo_tb_parampkg.sv");
			$fdisplay(f, "package g_fifo_tb_parampkg;");
			$fdisplay(f, "  parameter FIFO_WIDTH = %0d;",Width);
			$fdisplay(f, "  parameter FIFO_DEPTH = %0d;",Depth);
			$fdisplay(f, "  parameter FWFT = %0b;",FWFT);
			$fdisplay(f, "  parameter Enable_Port = %0b;",Enable_Port);
			$fdisplay(f, "  parameter Reset_Port = %0b;",Reset_Port);
			$fdisplay(f, "  parameter Data_Count_Port = %0b;",Data_Count_Port);
			$fdisplay(f, "  parameter Almost_Empty_Port = %0b;",Almost_Empty_Port);
			$fdisplay(f, "  parameter Almost_Full_Port = %0b;",Almost_Full_Port);
			$fdisplay(f, "  parameter Almost_Empty_Treshold = %0d;",Almost_Empty_Treshold);
			$fdisplay(f, "  parameter Almost_Full_Treshold = %0d;",Almost_Full_Treshold);
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
