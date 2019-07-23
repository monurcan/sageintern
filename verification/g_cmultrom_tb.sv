`include "p_memfuncs.sv"

interface intf(input logic clk, reset);
	logic en;
	logic [(g_cmultrom_tb_parampkg::Width-1):0] address;

	logic [(g_cmultrom_tb_parampkg::Width+clogb2(g_cmultrom_tb_parampkg::Constant_Value)+1):0] DOUT;
endinterface

class transaction;
	rand bit [(g_cmultrom_tb_parampkg::Width-1):0] address;
	constraint C {address < 257;}

	bit en;

	bit [(g_cmultrom_tb_parampkg::Width+clogb2(g_cmultrom_tb_parampkg::Constant_Value)+1):0] DOUT;

	function void display(string name);
		$display("-------------------------");
		$display("- %s ",name);
		$display("-------------------------");
		$display("- addr=%0d", address);
		$display("- DOUT = %0d",DOUT);
		$display("-------------------------");
	endfunction
endclass

class generator;
	rand transaction trans;
	mailbox gen2driv;

	function new(mailbox gen2driv);
		this.gen2driv = gen2driv;
	endfunction

	task main(); 
		forever begin
			trans = new();
			if(!trans.randomize()) $fatal("Gen:: trans randomization failed");   
			gen2driv.put(trans); #5;
		end
	endtask
endclass

class driver;
	int no_transactions;
	virtual intf vif;
	mailbox gen2driv;

	covergroup cg;
		// read all the addresses
		coverpoint vif.address {
			bins range[257] = {[0:256]};
		}
	endgroup

	real coverage;
	event covered;

	function new(virtual intf vif,mailbox gen2driv);
		this.vif = vif;
		this.gen2driv = gen2driv;
		this.cg= new();
	endfunction

	function real get_coverage;
		$display("-------------------------");
		$display("- [ Driver ] ");
		$display("-------------------------");
		$display("- coverage = %0f",coverage);
		$display("-------------------------");
		return coverage;
	endfunction

	task reset;
		wait(vif.reset);
		//    $display("[ DRIVER ] ----- Reset Started -----");
		vif.address <= 0;
		vif.en <= 0;
		//    $display("[ DRIVER ] ----- Reset Ended   -----");
	endtask

	task main;
		forever begin
			transaction trans;
			gen2driv.get(trans);
			repeat(10)
			@(posedge vif.clk);
			vif.en <= 1;
			vif.address <= trans.address;
			@(posedge vif.clk);
			vif.en <= 0;
			//trans.DOUT = vif.DOUT;
		
			cg.sample();
			coverage = cg.get_inst_coverage();
			if(this.get_coverage()==100) begin -> covered; break; end

			//@(posedge vif.clk);
			//      trans.display("[ Driver ]");
			no_transactions++;
		end
	endtask
endclass

class monitor;
	virtual intf vif;

	mailbox mon2scb;

	function new(virtual intf vif,mailbox mon2scb);
		this.vif = vif;
		this.mon2scb = mon2scb;
	endfunction
	
	task main;
		forever begin
			transaction trans;
			trans = new();
			//repeat(100)
			@(posedge vif.clk);
			trans.address = vif.address;
			trans.en = vif.en;

			trans.DOUT = vif.DOUT;

			//@(posedge vif.clk);
			mon2scb.put(trans);
			// trans.display("[ Monitor ]");
		end
	endtask
endclass

class scoreboard;
	mailbox mon2scb;
	int no_transactions;
	int no_errors=0;
	typedef bit[(g_cmultrom_tb_parampkg::Width+clogb2(g_cmultrom_tb_parampkg::Constant_Value)+1):0] t_cmultrom[256:0];
	typedef bit[(g_cmultrom_tb_parampkg::Width+clogb2(g_cmultrom_tb_parampkg::Constant_Value)+1):0] t_pipe[(g_cmultrom_tb_parampkg::Latency-1):0];

	function new(mailbox mon2scb);
		this.mon2scb = mon2scb;
	endfunction

	function t_cmultrom initramfcmultromfile (input string ramfilename, integer r_width, integer r_depth);
		int ramfile = $fopen(ramfilename, "r");
		t_cmultrom v_ram_name;

		for(int v_i=0; v_i<r_depth; v_i++)
			$fscanf(ramfile, "%b", v_ram_name[v_i]);

		return v_ram_name;
	endfunction
	
	function t_cmultrom init_fcmultrom_file_or_zeroes(input string ramfile, integer r_width, integer r_depth);	
		t_cmultrom v_ram_name_0;

	        if(ramfile != "All zeros")
	            v_ram_name_0 = initramfcmultromfile(ramfile, r_width, r_depth);

		return v_ram_name_0;
	endfunction

	task main;
		transaction trans;

		bit[(g_cmultrom_tb_parampkg::Width-1):0] res, Rom_Data;
		t_pipe pipe_reg;
		bit Enable_Inside;
		t_cmultrom SP_ROM = init_fcmultrom_file_or_zeroes(g_cmultrom_tb_parampkg::DATA_FILE, (g_cmultrom_tb_parampkg::Width+clogb2(g_cmultrom_tb_parampkg::Constant_Value)+2), 256);

		forever begin
			mon2scb.get(trans);
			trans.display("[ Scoreboard ]");

			Enable_Inside = g_cmultrom_tb_parampkg::Enable_Port ? trans.en : 1;
			Rom_Data = SP_ROM[trans.address];

			if(g_cmultrom_tb_parampkg::Latency == 0) res = Rom_Data;
			
			if(g_cmultrom_tb_parampkg::Latency == 1) res = pipe_reg[0];
			
			if(g_cmultrom_tb_parampkg::Latency > 1 && Enable_Inside) res = pipe_reg[g_cmultrom_tb_parampkg::Latency-1];
			
			if(res == trans.DOUT) $display("Result is as Expected (%0d:%0d)\n", no_transactions-no_errors, no_transactions);
			else $error("WRONG#%0d!\n\tExpected: %0d Actual: %0d\n",++no_errors, res, trans.DOUT);
	
			if(g_cmultrom_tb_parampkg::Latency > 0 && Enable_Inside) pipe_reg[0] = Rom_Data;
			if(g_cmultrom_tb_parampkg::Latency > 1 && Enable_Inside)
				pipe_reg[(g_cmultrom_tb_parampkg::Latency-1):1] = pipe_reg[(g_cmultrom_tb_parampkg::Latency-2):0];
		
			no_transactions++;
		end
	endtask
endclass

class environment;
	generator  gen;
	driver     driv;
	monitor    mon;
	scoreboard scb;

	mailbox gen2driv;
	mailbox mon2scb;

	virtual intf vif;

	function new(virtual intf vif);
		this.vif = vif;

		gen2driv = new();
		mon2scb  = new();

		gen  = new(gen2driv);
		driv = new(vif,gen2driv);
		mon  = new(vif,mon2scb);
		scb  = new(mon2scb);
	endfunction
	task pre_test();
		driv.reset();
	endtask
	task test();
		fork
			gen.main();
			driv.main();
			mon.main();
			scb.main();
		join_any
	endtask
   	task post_test();
		wait(driv.covered.triggered); // coverage driven
	endtask
	task run;
		pre_test();
		test();
		post_test();
		$stop;
	endtask
endclass

program test(intf intf);
	environment env;

	initial begin
		env = new(intf);
		env.run();
	end
endprogram

module g_cmultrom_tbench_top;
	bit clk;
	bit reset;

	initial begin
		reset = 1;
		#10 reset = 0;

		#1000 reset = 1;
		#10 reset = 0;
	end

	always #5 clk++;

	intf i_intf(clk,reset);
	test t1(i_intf);
   
	g_cmultrom #(
			.Latency(g_cmultrom_tb_parampkg::Latency),
			.AWidth(g_cmultrom_tb_parampkg::Width),
			.Signed_Unsigned(g_cmultrom_tb_parampkg::Signed_Unsigned),
			.DATA_FILE(g_cmultrom_tb_parampkg::DATA_FILE),
			.Enable_Port(g_cmultrom_tb_parampkg::Enable_Port),
			.Constant_Value(g_cmultrom_tb_parampkg::Constant_Value)
		) DUT (
			.CLK(i_intf.clk),
			.EN(i_intf.en),
			.A_SIG(i_intf.address),
			.P_SIG(i_intf.DOUT)
		);
endmodule
