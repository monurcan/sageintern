module g_rom_param_generate;
	class A;
		rand int unsigned Width, Depth, Latency;
		rand bit Enable_Port, file;

		constraint C { Latency <= 256; Width inside {[1:256]}; Depth inside {[1:65536]}; }

		function void printPackage;
			int f = $fopen("g_rom_tb_parampkg.sv");
			$fdisplay(f, "package g_rom_tb_parampkg;");
			$fdisplay(f, "  parameter Latency = %0d;",Latency);
			$fdisplay(f, "  parameter Width = %0d;",Width);
			$fdisplay(f, "  parameter Depth = %0d;",Depth);
			$fdisplay(f, "  parameter Enable_Port = %0b;",Enable_Port);
			if(file) $fdisplay(f, "  parameter DATA_FILE = \"C:\\\\questasim64_10.4c\\\\examples\\\\g_rom_data.txt\";");
			else $fdisplay(f, "  parameter DATA_FILE = \"All zeros\";");
			$fdisplay(f, "endpackage");
		endfunction

		function void printData;
			int f = $fopen("g_rom_data.txt");
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
