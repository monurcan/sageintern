interface intf(input logic clk, reset);
	logic en;
	logic [(g_register_tb_parampkg::Width-1):0] data;

	logic [(g_register_tb_parampkg::Width-1):0] DOUT;
endinterface

class transaction;
	rand bit [(g_register_tb_parampkg::Width-1):0] data;
	bit en, reset;

	bit [(g_register_tb_parampkg::Width-1):0] DOUT;

	function void display(string name);
		$display("-------------------------");
		$display("- %s ",name);
		$display("-------------------------");
		$display("- data=%0d",data);
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
		coverpoint vif.data;
	endgroup

	real coverage;
	event  covered;

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
		vif.data <= 0;
		vif.en <= 0;
		wait(!vif.reset);
		//    $display("[ DRIVER ] ----- Reset Ended   -----");
	endtask

	task main;
		forever begin
			transaction trans;
			gen2driv.get(trans);
			repeat(10)
			@(posedge vif.clk);
			vif.en <= 1;
			vif.data <= trans.data;
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
			trans.data = vif.data;
			trans.en = vif.en;
			trans.reset = vif.reset;

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

	function new(mailbox mon2scb);
		this.mon2scb = mon2scb;
	endfunction
		
	task main;
		transaction trans;
		bit[(g_register_tb_parampkg::Width-1):0] res;
		bit Enable_inside, Reset;

		forever begin
			mon2scb.get(trans);
			trans.display("[ Scoreboard ]");

			Enable_inside = g_register_tb_parampkg::Enable_Port ? trans.en : 1;
			Reset = g_register_tb_parampkg::Reset_Port ? trans.reset : 0;			

			if(Reset) res = g_register_tb_parampkg::Initial_Value;
			else if(Enable_inside) res = trans.data;

			if(res == trans.DOUT) $display("Result is as Expected (%0d:%0d)\n", no_transactions-no_errors, no_transactions);
			else $error("WRONG#%0d!\n\tExpected: %0d Actual: %0d\n",++no_errors, res, trans.DOUT);

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

module g_register_tbench_top;
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
   
	g_register #(
			.Initial_Value(g_register_tb_parampkg::Initial_Value),
			.Width(g_register_tb_parampkg::Width),
			.Enable_Port(g_register_tb_parampkg::Enable_Port),
			.Reset_Port(g_register_tb_parampkg::Reset_Port)
		) DUT (
			.CLK(i_intf.clk),
			.EN(i_intf.en),
			.DATA(i_intf.data),
			.RST(i_intf.reset),
			.DOUT(i_intf.DOUT)
		);
endmodule
