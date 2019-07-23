module g_truedpram_param_generate;
	class A;
		rand int unsigned Width, Depth, Latency_A, Latency_B, Write_Mode;
		rand bit Enable_Port_A, Enable_Port_B, Reset_Port_A, Reset_Port_B, file, Two_CLK;

		constraint C {
			Latency_A inside {[1:256]};
			Latency_B inside {[1:256]};
			Depth inside {[1:65536]};
			Write_Mode < 3;
			Width inside {[1:256]};
		}

		function void printPackage;
			int f = $fopen("g_truedpram_tb_parampkg.sv");
			$fdisplay(f, "package g_truedpram_tb_parampkg;");
			$fdisplay(f, "  parameter RAM_WIDTH = %0d;",Width);
			$fdisplay(f, "  parameter RAM_DEPTH = %0d;",Depth);
			if(file) $fdisplay(f, "  parameter INIT_FILE = \"C:\\\\questasim64_10.4c\\\\examples\\\\Ram_Initial_Data.dat\";");
			else $fdisplay(f, "  parameter INIT_FILE = \"All zeros\";");
			$fdisplay(f, "  parameter Write_Mode = %0d;",Write_Mode);
			$fdisplay(f, "  parameter Enable_Port_A = %0b;",Enable_Port_A);
			$fdisplay(f, "  parameter Reset_Port_A = %0b;",Reset_Port_A);
			$fdisplay(f, "  parameter Enable_Port_B = %0b;",Enable_Port_B);
			$fdisplay(f, "  parameter Reset_Port_B = %0b;",Reset_Port_B);
			$fdisplay(f, "  parameter Two_CLK = %0b;",Two_CLK);
			$fdisplay(f, "  parameter Latency_A = %0d;",Latency_A);
			$fdisplay(f, "  parameter Latency_B = %0d;",Latency_B);
			$fdisplay(f, "endpackage");
		endfunction

		function void printData;
			int f = $fopen("Ram_Initial_Data.dat");
			bit a;
			string line;
			for(int i = 0; i < Depth; i++) begin
				for(int j = 0; j < Width; j++) $fwrite(f, "%1b", $urandom()%2);
				$fwrite(f, "\n");
			end
		endfunction
	endclass

	A a;
	initial begin
		a = new();
		a.randomize();
		a.printPackage();
		a.printData();
	end
endmodule
