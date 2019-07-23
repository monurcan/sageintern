
module g_spram_param_generate;
	class A;
		rand int unsigned Width, Depth, Latency, Write_Mode;
		rand bit Enable_Port, Reset_Port, file, Memory_Type;

		constraint C {
			Latency inside {[1:256]};
			Depth inside {[1:65536]};
			Write_Mode < 3;
			Width inside {[1:256]};
		}

		function void printPackage;
			int f = $fopen("g_spram_tb_parampkg.sv");
			$fdisplay(f, "package g_spram_tb_parampkg;");
			$fdisplay(f, "  parameter RAM_WIDTH = %0d;",Width);
			$fdisplay(f, "  parameter RAM_DEPTH = %0d;",Depth);
			if(file) $fdisplay(f, "  parameter INIT_FILE = \"C:\\\\questasim64_10.4c\\\\examples\\\\Ram_Initial_Data.dat\";");
			else $fdisplay(f, "  parameter INIT_FILE = \"All zeros\";");
			$fdisplay(f, "  parameter Memory_Type = %0b;",Memory_Type);
			$fdisplay(f, "  parameter Write_Mode = %0d;",Write_Mode);
			$fdisplay(f, "  parameter Enable_Port = %0b;",Enable_Port);
			$fdisplay(f, "  parameter Reset_Port = %0b;",Reset_Port);
			$fdisplay(f, "  parameter Latency = %0d;",Latency);
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