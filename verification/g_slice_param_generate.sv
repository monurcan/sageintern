module g_slice_param_generate;
	class A;
		rand int unsigned Input_Width;
		rand int unsigned Slice_Width;
		rand int unsigned Specify_range_as;
		rand int unsigned Low_Bit;
		constraint C { solve Input_Width, Slice_Width before Low_Bit;
				Slice_Width <= Input_Width;
				Low_Bit < (Input_Width+1-Slice_Width);
				Specify_range_as inside {[0:3]};
				Input_Width inside {[0:256]};
				}

		function void printPackage;
			int f = $fopen("g_slice_tb_parampkg.sv");
			$fdisplay(f, "package g_slice_tb_parampkg;");
			$fdisplay(f, "  parameter Input_Width = %0d;",Input_Width);
			$fdisplay(f, "  parameter Slice_Width = %0d;",Slice_Width);
			$fdisplay(f, "  parameter Specify_range_as = %0d;",Specify_range_as);
			$fdisplay(f, "  parameter High_Bit = %0d;",Low_Bit + Slice_Width - 1);
			$fdisplay(f, "  parameter Low_Bit = %0d;",Low_Bit);
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
