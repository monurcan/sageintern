`define TEST_SIZE (100)
`define PERIOD (g_leadingdet_tb_parampkg::Latency+`TEST_SIZE)

interface intf(input logic clk,reset);
	logic en;
	logic [(g_leadingdet_tb_parampkg::A_Width-1):0] a;
	logic [(g_leadingdet_tb_parampkg::A_Width-1):0] detected;
endinterface

class transaction;
	rand bit [(g_leadingdet_tb_parampkg::A_Width-1):0] a;

	bit [(g_leadingdet_tb_parampkg::A_Width-1):0] detected;

	function void display(string name);
		$display("-------------------------");
		$display("- %s ",name);
		$display("-------------------------");
		$display("- A = %0b",a);
		$display("- detected = %0d",detected);
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
		vif.en <= 0;
		wait(!vif.reset);
		//    $display("[ DRIVER ] ----- Reset Ended   -----");
	endtask

	task main;
		forever begin
			transaction trans;
			gen2driv.get(trans);
			repeat(`PERIOD)
			@(posedge vif.clk);
			vif.en <= 1;
			vif.a <= trans.a;
			@(posedge vif.clk);
			vif.en <= 0;
			trans.detected = vif.detected;
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
			repeat(`PERIOD)
			@(posedge vif.clk);
			trans.a = vif.a;

			trans.detected = vif.detected;

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
		bit[(g_leadingdet_tb_parampkg::A_Width-1):0] add_1, add_1_r, reverse_A, add_1_n, add_1_r_n, reverse_A_n, pre_detected, pre_detected_r;

		forever begin
			mon2scb.get(trans);
			trans.display("[ Scoreboard ]");
			
			if(g_leadingdet_tb_parampkg::Detect_from) begin
				if(g_leadingdet_tb_parampkg::Detect_Value) begin
					for(int v_i=0; v_i<g_leadingdet_tb_parampkg::A_Width; v_i++) reverse_A[v_i] = trans.a[g_leadingdet_tb_parampkg::A_Width - 1 - v_i];
					add_1_r = ~reverse_A + 1;
					pre_detected_r = add_1_r & reverse_A;
				end else begin
					for(int v_in=0; v_in<g_leadingdet_tb_parampkg::A_Width; v_in++) reverse_A_n[v_in] = ~trans.a[g_leadingdet_tb_parampkg::A_Width - 1 - v_in];
					add_1_r_n = reverse_A_n + 1;
					pre_detected_r = add_1_r_n & reverse_A_n;
				end

				for(int v_io=0; v_io < g_leadingdet_tb_parampkg::A_Width; v_io++) pre_detected[v_io] = pre_detected_r[g_leadingdet_tb_parampkg::A_Width - 1 - v_io];
			end else begin
				if(g_leadingdet_tb_parampkg::Detect_Value) begin
					add_1 = ~trans.a + 1;
					pre_detected = add_1 & trans.a;
				end else begin
					add_1_n = trans.a + 1;
					pre_detected = add_1_n & ~trans.a;
				end
			end

			if(pre_detected == trans.detected) $display("Result is as Expected (%0d:%0d)\n", no_transactions-no_errors, no_transactions);
			else $error("WRONG#%0d!\n\tExpected: %0b Actual: %0b\n",++no_errors, pre_detected, trans.detected);
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

module g_leadingdet_tbench_top;
	bit clk;
	bit reset;

	always #5 clk = ~clk;

	initial begin
		reset = 1;
		#5 reset = 0;
	end

	intf i_intf(clk,reset);
	test t1(i_intf);
   
	g_leadingdet #(
		.Latency(g_leadingdet_tb_parampkg::Latency),
		.Detect_from(g_leadingdet_tb_parampkg::Detect_from),
		.Detect_Value(g_leadingdet_tb_parampkg::Detect_Value),
		.Port_Width(g_leadingdet_tb_parampkg::A_Width),
		.Enable_Port(g_leadingdet_tb_parampkg::Enable_Port)
		) DUT (
			.CLK(i_intf.clk),
			.EN(i_intf.en),
			.A_SIG(i_intf.a),
			.DETECTED(i_intf.detected)
		);

	initial begin
		$dumpfile("dump.vcd"); $dumpvars;
	end
endmodule
