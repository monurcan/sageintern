`define TEST_SIZE (50)

interface intf(input logic clk,reset);
	logic [(g_slice_tb_parampkg::Input_Width-1):0] a;
	logic [(g_slice_tb_parampkg::Slice_Width-1):0] p_sig;
endinterface

class transaction;
	rand bit [(g_slice_tb_parampkg::Input_Width-1):0] a;

	bit [(g_slice_tb_parampkg::Slice_Width-1):0] p_sig;

	function void display(string name);
		$display("-------------------------");
		$display("- %s ",name);
		$display("-------------------------");
		$display("- A = %0d",a);
		$display("- p_sig = %0d",p_sig);
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

	task reset;
		wait(vif.reset);
		//    $display("[ DRIVER ] ----- Reset Started -----");
		vif.a <= 0;
		wait(!vif.reset);
		//    $display("[ DRIVER ] ----- Reset Ended   -----");
	endtask

	task main;
		forever begin
			transaction trans;
			gen2driv.get(trans);
			@(posedge vif.clk);
			vif.a <= trans.a;
			@(posedge vif.clk);
			trans.p_sig = vif.p_sig;
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
			trans.a = vif.a;

			trans.p_sig = vif.p_sig;

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
		logic[(g_slice_tb_parampkg::Slice_Width-1):0] res;
		forever begin
			mon2scb.get(trans);
			trans.display("[ Scoreboard ]");
			case (g_slice_tb_parampkg::Specify_range_as)
				0: res = trans.a[g_slice_tb_parampkg::High_Bit:g_slice_tb_parampkg::Low_Bit];
				1: res = trans.a[g_slice_tb_parampkg::High_Bit:(g_slice_tb_parampkg::High_Bit-g_slice_tb_parampkg::Slice_Width+1)];
				3: res = trans.a[(g_slice_tb_parampkg::Low_Bit+g_slice_tb_parampkg::Slice_Width-1):g_slice_tb_parampkg::Low_Bit];
			endcase

			if(res == trans.p_sig) $display("Result is as Expected (%0d:%0d)\n", no_transactions-no_errors, no_transactions);
			else $error("WRONG#%0d!\n\tExpected: %0d Actual: %0d\n",++no_errors, res, trans.p_sig);

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

module g_slice_tbench_top;
	bit clk;
	bit reset;

	always #5 clk = ~clk;

	initial begin
		reset = 1;
		#5 reset =0;
	end

	intf i_intf(clk,reset);
	test t1(i_intf);
   
	g_slice #(
		.Input_Width($unsigned(g_slice_tb_parampkg::Input_Width)),
		.Specify_range_as(g_slice_tb_parampkg::Specify_range_as),
		.Slice_Width($unsigned(g_slice_tb_parampkg::Slice_Width)),
		.Low_Bit($unsigned(g_slice_tb_parampkg::Low_Bit)),
		.High_Bit($unsigned(g_slice_tb_parampkg::High_Bit))
		) DUT (
			.A_SIG(i_intf.a),
			.SLICE(i_intf.p_sig)
		);
   
	initial begin
		$dumpfile("dump.vcd"); $dumpvars;
	end
endmodule
