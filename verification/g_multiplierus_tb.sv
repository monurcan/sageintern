interface intf(input logic clk,reset);
	logic en;
	logic [(g_multiplierus_tb_parampkg::A_Width-1):0] a;
	logic [(g_multiplierus_tb_parampkg::B_Width-1):0] b;
	logic [(g_multiplierus_tb_parampkg::A_Width+g_multiplierus_tb_parampkg::B_Width-1):0] axb;
endinterface

class transaction;
	rand bit [(g_multiplierus_tb_parampkg::A_Width-1):0] a;
	rand bit [(g_multiplierus_tb_parampkg::B_Width-1):0] b;

	bit [(g_multiplierus_tb_parampkg::A_Width+g_multiplierus_tb_parampkg::B_Width-1):0] axb;

	function void display(string name);
		$display("-------------------------");
		$display("- %s ",name);
		$display("-------------------------");
		$display("- A = %0d, B = %0d",a,b);
		$display("- axb = %0d",axb);
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

	function new(virtual intf vif,mailbox gen2driv);
		this.vif = vif;
		this.gen2driv = gen2driv;
	endfunction

	task reset;
		wait(vif.reset);
		//    $display("[ DRIVER ] ----- Reset Started -----");
		vif.a <= 0;
		vif.b <= 0;
		vif.en <= 0;
		wait(!vif.reset);
		//    $display("[ DRIVER ] ----- Reset Ended   -----");
	endtask

	task main;
		forever begin
			transaction trans;
			gen2driv.get(trans);

			@(posedge vif.clk);
			vif.en <= 1;
			vif.a <= trans.a;
			vif.b <= trans.b;
			@(posedge vif.clk);
			vif.en <= 0;
			trans.axb = vif.axb;
			@(posedge vif.clk);
			//      trans.display("[ Driver ]");
			no_transactions++;
		end
	endtask
endclass

class monitor;
	virtual intf vif;

	mailbox mon2scb;
	
	covergroup cg;
		coverpoint vif.a {
			option.auto_bin_max = 3;
		}
		coverpoint vif.b {
			option.auto_bin_max = 3;
		}
		cross vif.a, vif.b;
	endgroup

	real coverage;
	event  covered;

	function new(virtual intf vif,mailbox mon2scb);
		this.vif = vif;
		this.mon2scb = mon2scb;
		this.cg= new();
	endfunction

	function real get_coverage;
		$display("-------------------------");
		$display("- [ Monitor ] ");
		$display("-------------------------");
		$display("- coverage = %0f",coverage);
		$display("-------------------------");
		return coverage;
	endfunction

	task main;
		forever begin
			transaction trans;
			trans = new();

			@(posedge vif.clk);
			trans.a = vif.a;
			trans.b = vif.b;

			trans.axb = vif.axb;
			cg.sample();
			coverage = cg.get_inst_coverage();
			if(this.get_coverage()==100) begin -> covered; break; end

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
		logic[(g_multiplierus_tb_parampkg::A_Width+g_multiplierus_tb_parampkg::B_Width-1):0] res = 0;
		forever begin
			mon2scb.get(trans);
			trans.display("[ Scoreboard ]");

			res =  trans.a*trans.b;
			if(res == trans.axb) $display("Result is as Expected (%0d:%0d)\n", no_transactions-no_errors, no_transactions);
			else $error("WRONG#%0d!\n\tExpected: %0d Actual: %0d\n",++no_errors, res, trans.axb);

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
		wait(mon.covered.triggered); // coverage driven
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

module g_multiplierus_tbench_top;
	bit clk;
	bit reset;

	always #5 clk = ~clk;

	initial begin
		reset = 1;
		#5 reset =0;
	end

	intf i_intf(clk,reset);
	test t1(i_intf);
   
	g_multiplierus #(
		.AWidth(g_multiplierus_tb_parampkg::A_Width),
		.BWidth(g_multiplierus_tb_parampkg::B_Width),
		.Enable_Port(g_multiplierus_tb_parampkg::Enable_Port)
		) DUT (
			.B_SIG(i_intf.b),
			.A_SIG(i_intf.a),
			.EN(i_intf.en),
			.AXB(i_intf.axb)
		);
   
	initial begin
		$dumpfile("dump.vcd"); $dumpvars;
	end
endmodule
