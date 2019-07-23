`define TEST_SIZE (50)
`define PERIOD (g_addsub_tb_parampkg::Latency+`TEST_SIZE)

interface intf(input logic clk,reset);
	logic en;
	logic [(g_addsub_tb_parampkg::Width-1):0] a;
	logic [(g_addsub_tb_parampkg::Width-1):0] b;
	logic [(g_addsub_tb_parampkg::Width-1):0] sum;

	logic C_IN;
	logic SUB;
	logic C_OUT;

endinterface

class transaction;
	rand bit [(g_addsub_tb_parampkg::Width-1):0] a;
	rand bit [(g_addsub_tb_parampkg::Width-1):0] b;
	rand bit C_IN;
	rand bit SUB;

	bit [(g_addsub_tb_parampkg::Width-1):0] sum;
	bit C_OUT;

	function void display(string name);
		$display("-------------------------");
		$display("- %s ",name);
		$display("-------------------------");
		if(g_addsub_tb_parampkg::Signed_Unsigned) begin
		$display("- A = %0d, B = %0d",$signed(a),$signed(b));
		$display("- C.SUM = %0b.%0b = %0d", C_OUT, sum, $signed(sum));
		end else begin
		$display("- A = %0d, B = %0d",a,b);
		$display("- C.SUM = %0d",{C_OUT,sum});
		end
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
		vif.b <= 0;
		vif.en <= 0;
		vif.C_IN <= 0;
		vif.SUB <= 0;
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
			vif.b <= trans.b;
			vif.C_IN <= trans.C_IN;
			vif.SUB <= trans.SUB;
			@(posedge vif.clk);
			vif.en <= 0;
			trans.sum = vif.sum;
			trans.C_OUT = vif.C_OUT;
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
			trans.b = vif.b;
			trans.C_IN = vif.C_IN;
			trans.SUB = vif.SUB;

			trans.sum = vif.sum;
			trans.C_OUT = vif.C_OUT;
	
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
		logic[g_addsub_tb_parampkg::Width:0] res = 0;
		bit is_subs;
		forever begin
			mon2scb.get(trans);
			trans.display("[ Scoreboard ]");
			is_subs = g_addsub_tb_parampkg::Operation==1 || ((g_addsub_tb_parampkg::Operation==2 || g_addsub_tb_parampkg::Operation==3) && trans.SUB);

			if(g_addsub_tb_parampkg::Signed_Unsigned) begin
			// Signed
			res =  is_subs ? ($signed(trans.a)-$signed(trans.b)) : ($signed(trans.a)+$signed(trans.b));
			res = (g_addsub_tb_parampkg::Carry_In_Port) ? (is_subs ? ((res)-$signed(trans.C_IN)) : ((res)+$signed(trans.C_IN))) : res;

			if(res[(g_addsub_tb_parampkg::Width-1):0] == trans.sum && (!g_addsub_tb_parampkg::Carry_Out_Port || res[g_addsub_tb_parampkg::Width]==trans.C_OUT)) $display("Result is as Expected (%0d:%0d)\n", no_transactions-no_errors, no_transactions);
			else $error("WRONG#%0d!\n\tExpected: %1b.%0b Actual: %1b.%0b\n",++no_errors, res[g_addsub_tb_parampkg::Width],$signed(res[(g_addsub_tb_parampkg::Width-1):0]), trans.C_OUT, $signed(trans.sum));
			
			end else begin
			// Unsigned
			res =  is_subs ? (trans.a-trans.b) : (trans.a+trans.b);
			res += (g_addsub_tb_parampkg::Carry_In_Port) ? (is_subs ? -trans.C_IN : trans.C_IN) : 0;
			if(!g_addsub_tb_parampkg::Carry_Out_Port) res[g_addsub_tb_parampkg::Width] = 0;

			if(res == {trans.C_OUT, trans.sum}) $display("Result is as Expected (%0d:%0d)\n", no_transactions-no_errors, no_transactions);
			else $error("WRONG#%0d!\n\tExpected: %0d Actual: %0d\n",++no_errors, res,{trans.C_OUT, trans.sum});
			
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

module g_addsub_tbench_top;
	bit clk;
	bit reset;

	always #5 clk = ~clk;

	initial begin
		reset = 1;
		#5 reset =0;
	end

	intf i_intf(clk,reset);
	test t1(i_intf);
   
	g_addsub #(
		.Operation(g_addsub_tb_parampkg::Operation),
		.Latency(g_addsub_tb_parampkg::Latency),
		.Signed_Unsigned(g_addsub_tb_parampkg::Signed_Unsigned),
		.Width(g_addsub_tb_parampkg::Width),
		.Reset_Port(g_addsub_tb_parampkg::Reset_Port),
		.Carry_In_Port(g_addsub_tb_parampkg::Carry_In_Port),
		.Carry_Out_Port(g_addsub_tb_parampkg::Carry_Out_Port),
		.Enable_Port(g_addsub_tb_parampkg::Enable_Port)
		) DUT (
			.CLK(i_intf.clk),
			.RST(i_intf.reset),
			.B_SIG(i_intf.b),
			.A_SIG(i_intf.a),
			.EN(i_intf.en),
			.SUM(i_intf.sum),
			.C_IN(i_intf.C_IN),
			.SUB(i_intf.SUB),
			.C_OUT(i_intf.C_OUT)
		);
   
	initial begin
		$dumpfile("dump.vcd"); $dumpvars;
	end
endmodule
