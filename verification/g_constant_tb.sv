`define TEST_SIZE (50)

interface intf(input logic clk);
	logic signed [(g_constant_tb_parampkg::Port_Width-1):0] OUT;
endinterface

class transaction;
	logic signed [(g_constant_tb_parampkg::Port_Width-1):0] OUT;

	function void display(string name);
		$display("-------------------------");
		$display("- %s ",name);
		$display("-------------------------");
		$display("- CONSTANT\t=\t%0d",g_constant_tb_parampkg::Constant_Value);
		$display("- OUT\t=\t%0d",OUT);
		$display("-------------------------");
	endfunction
endclass

class generator;
	rand transaction trans;
	mailbox gen2driv;
	int  repeat_count; 
	event ended;
	
	function new(mailbox gen2driv);
		this.gen2driv = gen2driv;
	endfunction

	task main(); 
		repeat(repeat_count) begin
			trans = new();
			if(!trans.randomize()) $fatal("Gen:: trans randomization failed");   
			gen2driv.put(trans);
		end
		-> ended;
	endtask
endclass

class driver;
	int no_transactions;
	virtual intf vif;
	mailbox gen2driv;

	function new(virtual intf vif,mailbox gen2driv);
		this.vif = vif;
		this.gen2driv = gen2driv;
	endfunction

	task main;
		forever begin
			transaction trans;
			gen2driv.get(trans);
			@(posedge vif.clk);
			trans.OUT = vif.OUT;
			@(posedge vif.clk);
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
			
			@(posedge vif.clk);
			trans.OUT = vif.OUT;
	
			@(posedge vif.clk);
			mon2scb.put(trans);
			// trans.display("[ Monitor ]");
		end
	endtask
endclass

class scoreboard;
	mailbox mon2scb;
	int no_transactions;
	int no_errors=0;

	function new(mailbox mon2scb);
		this.mon2scb = mon2scb;
	endfunction
		
	task main;
		transaction trans;

		forever begin
			mon2scb.get(trans);
			trans.display("[ Scoreboard ]");
			
			if($signed(g_constant_tb_parampkg::Constant_Value) == trans.OUT)
				$display("Result is as Expected (%0d:%0d)\n", no_transactions-no_errors, no_transactions);
			else begin
				$error("WRONG#%0d!\n\tExpected: %0d Actual: %0d\n", ++no_errors, g_constant_tb_parampkg::Constant_Value, trans.OUT);
			end
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
		wait(gen.ended.triggered);
		//wait((gen.repeat_count) == driv.no_transactions);
		wait((gen.repeat_count+1) == scb.no_transactions);
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
		env.gen.repeat_count = `TEST_SIZE;
		env.run();
	end
endprogram

module g_constant_tbench_top;
	bit clk;

	always #5 clk = ~clk;

	intf i_intf(clk);
	test t1(i_intf);
   
	g_constant #(
		.Value_Width(g_constant_tb_parampkg::Port_Width),
		.Constant_Value(g_constant_tb_parampkg::Constant_Value)
		) DUT (
			.CONSTANT_OUT(i_intf.OUT)
		);
   
	initial begin
		$dumpfile("dump.vcd"); $dumpvars;
	end
endmodule
