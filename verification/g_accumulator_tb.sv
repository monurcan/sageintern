interface intf(input logic clk,reset);
	logic en;
	logic [(g_accumulator_tb_parampkg::Width-1):0] b;
	logic [(g_accumulator_tb_parampkg::Width-1):0] ACC_OUT;
endinterface

class transaction;
	rand bit [(g_accumulator_tb_parampkg::Width-1):0] b;
	bit en;

	bit [(g_accumulator_tb_parampkg::Width-1):0] ACC_OUT;

	function void display(string name);
		$display("-------------------------");
		$display("- %s ",name);
		$display("-------------------------");
		if(g_accumulator_tb_parampkg::Signed_Unsigned) begin
		$display("- B = %0d",$signed(b));
		$display("- ACC_OUT = %0d", $signed(ACC_OUT));
		end else begin
		$display("- B = %0d",b);
		$display("- ACC_OUT = %0d",ACC_OUT);
		end
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
		coverpoint vif.b;
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
		vif.b <= 0;
		vif.en <= 0;
		wait(!vif.reset);
		//    $display("[ DRIVER ] ----- Reset Ended   -----");
	endtask

	task main;
		forever begin
			transaction trans;
			gen2driv.get(trans);
			repeat(g_accumulator_tb_parampkg::Latency)
			@(posedge vif.clk);
			vif.en <= 1;
			vif.b <= trans.b;
			@(posedge vif.clk);
			vif.en <= 0;
			trans.ACC_OUT = vif.ACC_OUT;
		
			cg.sample();
			coverage = cg.get_inst_coverage();
			if(this.get_coverage()==100) begin -> covered; break; end

			// @(posedge vif.clk);
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
			trans.b = vif.b;
			trans.en = vif.en;

			trans.ACC_OUT = vif.ACC_OUT;

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
	bit[(g_accumulator_tb_parampkg::Width-1):0] past, active_b;

	function new(mailbox mon2scb);
		this.mon2scb = mon2scb;
	endfunction
		
	task main;
		transaction trans;
		logic[(g_accumulator_tb_parampkg::Width-1):0] res;
		int clock;
		bit Enable_Inside;

		forever begin
			mon2scb.get(trans);
			trans.display("[ Scoreboard ]");
			if(trans.en) clock = g_accumulator_tb_parampkg::Latency;
			if(--clock==0) active_b = trans.b;

//			$display("out = %3b", trans.ACC_OUT);
//			$display("active_b= %3b , past = %3b ... %3b\n", active_b, past, 1*past + active_b);
			Enable_Inside = g_accumulator_tb_parampkg::Enable_Port ? trans.en : 1;

			if(g_accumulator_tb_parampkg::Signed_Unsigned) begin
				// Signed
				res = Enable_Inside ? (g_accumulator_tb_parampkg::Operation ? ($signed(1*past)-$signed(active_b)) : ($signed(1*past)+$signed(active_b))) : $signed(past);
	
				if(res == trans.ACC_OUT) $display("Result is as Expected (%0d:%0d)\n", no_transactions-no_errors, no_transactions);
				else $error("WRONG#%0d!\n\tExpected: %0d Actual: %0d\n",++no_errors, $signed(res), $signed(trans.ACC_OUT));
				
			end else begin
				// Unsigned
				$display("clock=%0d, past=%0d, active_b=%0d", clock, past, active_b);
				res = Enable_Inside ? (g_accumulator_tb_parampkg::Operation ? (1*past-active_b) : (1*past+active_b)) : (past);
	
				if(res == trans.ACC_OUT) $display("Result is as Expected (%0d:%0d)\n", no_transactions-no_errors, no_transactions);
				else $error("WRONG#%0d!\n\tExpected: %0d Actual: %0d\n",++no_errors, res, trans.ACC_OUT);
				
			end

			past = trans.ACC_OUT;

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

module g_accumulator_tbench_top;
	bit clk;
	bit reset;

	always #5 clk = ~clk;

	initial begin
		reset = 1;
		#5 reset =0;
	end

	intf i_intf(clk,reset);
	test t1(i_intf);
   
	g_accumulator #(
		.Operation(g_accumulator_tb_parampkg::Operation),
		.Latency(g_accumulator_tb_parampkg::Latency),
		.Signed_Unsigned(g_accumulator_tb_parampkg::Signed_Unsigned),
		.Width(g_accumulator_tb_parampkg::Width),
		.Reset_Port(g_accumulator_tb_parampkg::Reset_Port),
		.Reset_Bypass(g_accumulator_tb_parampkg::Reset_Bypass),
		.Enable_Port(g_accumulator_tb_parampkg::Enable_Port)
		) DUT (
			.CLK(i_intf.clk),
			.RST(i_intf.reset),
			.B_SIG(i_intf.b),
			.EN(i_intf.en),
			.ACC_OUT(i_intf.ACC_OUT)
		);
   
	initial begin
		$dumpfile("dump.vcd"); $dumpvars;
	end
endmodule
