interface intf(input logic clk,reset);
	logic en;
	logic [(g_counter_tb_parampkg::Width-1):0] din;
	logic load;
	logic up;
	logic [(g_counter_tb_parampkg::Width-1):0] COUNT;
endinterface

class transaction;
	rand bit [(g_counter_tb_parampkg::Width-1):0] din;
	rand bit load;
	rand bit up;
	bit en;
	bit rst;

	bit [(g_counter_tb_parampkg::Width-1):0] COUNT;

	function void display(string name);
		$display("-------------------------");
		$display("- %s ",name);
		$display("-------------------------");
		$display("- load=%0b, up=%0b, din = %0d",load,up,din);
		$display("- COUNT = %0d",COUNT);
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
		coverpoint vif.din;
		coverpoint vif.load;
		coverpoint vif.up;
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
		vif.din <= 0;
		vif.load <= 0;
		vif.up <= 0;
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
			vif.din <= trans.din;
			vif.load <= trans.load;
			vif.up <= trans.up;
			@(posedge vif.clk);
			vif.en <= 0;
			//trans.COUNT = vif.COUNT;
		
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
			trans.din = vif.din;
			trans.up = vif.up;
			trans.load = vif.load;
			trans.en = vif.en;
			trans.rst = vif.reset;

			trans.COUNT = vif.COUNT;

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
		bit[(g_counter_tb_parampkg::Width-1):0] res, past = g_counter_tb_parampkg::G_Initial_Value, sum, sub;
		bit Enable_Inside, Load_Inside, Limit_Exceeded, Limit_Exceeded_P, Reset;

		forever begin
			mon2scb.get(trans);
			trans.display("[ Scoreboard ]");

			Enable_Inside = g_counter_tb_parampkg::Enable_Port ? trans.en : 1;
			Load_Inside = g_counter_tb_parampkg::Load_Port ? trans.load : 0;
			Reset = g_counter_tb_parampkg::Reset_Port ? trans.rst : 0;

			if(g_counter_tb_parampkg::Out_type) begin
				sum = $unsigned(past) + g_counter_tb_parampkg::Step;
				sub = $unsigned(past) - g_counter_tb_parampkg::Step;
				Limit_Exceeded_P = $unsigned(past) == g_counter_tb_parampkg::Count_Limit;
			end else begin
				sum = $signed(past) + g_counter_tb_parampkg::Step;
				sub = $signed(past) - g_counter_tb_parampkg::Step;
				Limit_Exceeded_P = $signed(past) == g_counter_tb_parampkg::Count_Limit;
			end

			Limit_Exceeded = g_counter_tb_parampkg::Free_or_Limited ? Limit_Exceeded_P : 0;

			if(Reset)
				res = g_counter_tb_parampkg::G_Initial_Value;
			else
				if(Enable_Inside)
					if(Load_Inside)
						res = trans.din;
					else if(Limit_Exceeded)
						res = g_counter_tb_parampkg::G_Initial_Value;
					else
						res = ((g_counter_tb_parampkg::Direction == 2 && trans.up) || g_counter_tb_parampkg::Direction == 0) ? sum : sub;

			if(res == trans.COUNT) $display("Result is as Expected (%0d:%0d)\n", no_transactions-no_errors, no_transactions);
			else $error("WRONG#%0d!\n\tExpected: %0d Actual: %0d\n",++no_errors, res, trans.COUNT);
			

		//$display("out = %3b, sum = %0b", trans.COUNT, res);


//			$display("clock=%0d, past=%0d, active_b=%0d", clock, past, active_b);


//					res = Enable_Inside ? (g_counter_tb_parampkg::Operation ? (1*past-active_b) : (1*past+active_b)) : (past);
//						if(res == trans.COUNT) $display("Result is as Expected (%0d:%0d)\n", no_transactions-no_errors, no_transactions);
//					else $error("WRONG#%0d!\n\tExpected: %0d Actual: %0d\n",++no_errors, res, trans.COUNT);
//					
			past = trans.COUNT;

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

module g_counter_tbench_top;
	bit clk;
	bit reset;

	always #5 clk = ~clk;

	initial begin
		reset = 1;
		#1 reset = 0;
	end

	intf i_intf(clk,reset);
	test t1(i_intf);
   
	g_counter #(
			.Count_Limit(g_counter_tb_parampkg::Count_Limit),
			.Width(g_counter_tb_parampkg::Width),
			.Direction(g_counter_tb_parampkg::Direction),
			.G_Initial_Value(g_counter_tb_parampkg::G_Initial_Value),
			.Step(g_counter_tb_parampkg::Step),
			.Out_type(g_counter_tb_parampkg::Out_type),
			.Reset_Port(g_counter_tb_parampkg::Reset_Port),
			.Load_Port(g_counter_tb_parampkg::Load_Port),
			.Enable_Port(g_counter_tb_parampkg::Enable_Port),
			.Free_or_Limited(g_counter_tb_parampkg::Free_or_Limited)
		) DUT (
			.CLK(i_intf.clk),
			.RST(i_intf.reset),
			.EN(i_intf.en),
			.LOAD(i_intf.load),
			.UP(i_intf.up),
			.DIN(i_intf.din),
			.COUNT(i_intf.COUNT)
		);
endmodule
