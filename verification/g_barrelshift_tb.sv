`define TEST_SIZE (50)
`define PERIOD (g_barrelshift_tb_parampkg::Latency+`TEST_SIZE)

`include "p_memfuncs.sv"

interface intf(input logic clk,reset);
	logic en;
	logic [(g_barrelshift_tb_parampkg::A_Width-1):0] a;
	logic [(g_barrelshift_tb_parampkg::A_Width-1):0] z_sig;
	logic [(clogb2(g_barrelshift_tb_parampkg::A_Width)-1):0] pos;
	logic dir;
endinterface

class transaction;
	rand bit [(g_barrelshift_tb_parampkg::A_Width-1):0] a;
	rand bit [(clogb2(g_barrelshift_tb_parampkg::A_Width)-1):0] pos;
	rand bit dir;

	bit [(g_barrelshift_tb_parampkg::A_Width-1):0] z_sig;

	function void display(string name);
		$display("-------------------------");
		$display("- %s ",name);
		$display("-------------------------");
		$display("- A = %0b, pos = %0d, dir = %0b",a, pos, dir);
		$display("- z_sig = %0b",z_sig);
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
		vif.pos <= 0;
		vif.dir <= 0;
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
			vif.pos <= trans.pos;
			vif.dir <= trans.dir;
			@(posedge vif.clk);
			vif.en <= 0;
			trans.z_sig = vif.z_sig;
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
			trans.pos = vif.pos;
			trans.dir = vif.dir;

			trans.z_sig = vif.z_sig;

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
		bit[(g_barrelshift_tb_parampkg::A_Width-1):0] res;
		bit[(g_barrelshift_tb_parampkg::A_Width-1):0] stages[clogb2(g_barrelshift_tb_parampkg::A_Width)+1];

		forever begin
			mon2scb.get(trans);
			trans.display("[ Scoreboard ]");

			case(g_barrelshift_tb_parampkg::Direction)
			0: begin
				stages[0] = trans.a;
				for(int variable_i=1; variable_i<=clogb2(g_barrelshift_tb_parampkg::A_Width); variable_i++) begin
					if(trans.pos[variable_i - 1] == 0) stages[variable_i] = stages[variable_i - 1];
					else begin
						int k;
						for(k=0; k<(2**(variable_i - 1)); k++)
							stages[variable_i][k] = 0;
						for(k=0; k<(g_barrelshift_tb_parampkg::A_Width - 2**(variable_i - 1)); k++)
							stages[variable_i][k + (2**(variable_i - 1))] = stages[variable_i - 1][k];
					end
				end
				res = stages[clogb2(g_barrelshift_tb_parampkg::A_Width)];
			end
			1: begin
				stages[0] = trans.a;
				for(int variable_i=1; variable_i<=clogb2(g_barrelshift_tb_parampkg::A_Width); variable_i++) begin
					if(trans.pos[variable_i - 1] == 0) stages[variable_i] = stages[variable_i - 1];
					else begin
						int k;
						for(k=2**(variable_i - 1); k<g_barrelshift_tb_parampkg::A_Width; k++)
							stages[variable_i][k-2**(variable_i - 1)] = stages[variable_i - 1][k];
						for(k=0; k<2**(variable_i - 1); k++)
							stages[variable_i][k+g_barrelshift_tb_parampkg::A_Width-2**(variable_i - 1)] = 0;
					end
				end
				res = stages[clogb2(g_barrelshift_tb_parampkg::A_Width)];
			end
			2: begin
				
					stages[0] = trans.a;
					for(int variable_i=1; variable_i<=clogb2(g_barrelshift_tb_parampkg::A_Width); variable_i++) begin
						if(trans.pos[variable_i - 1] == 0) stages[variable_i] = stages[variable_i - 1];
						else begin
							int k;
							if(trans.dir == 0) begin
								for(k=0; k<(2**(variable_i - 1)); k++)
									stages[variable_i][k] = 0;
								for(k=0; k<(g_barrelshift_tb_parampkg::A_Width - 2**(variable_i - 1)); k++)
									stages[variable_i][k + (2**(variable_i - 1))] = stages[variable_i - 1][k];							
							end else begin
								for(k=2**(variable_i - 1); k<g_barrelshift_tb_parampkg::A_Width; k++)
									stages[variable_i][k-2**(variable_i - 1)] = stages[variable_i - 1][k];
								for(k=0; k<2**(variable_i - 1); k++)
									stages[variable_i][k+g_barrelshift_tb_parampkg::A_Width-2**(variable_i - 1)] = 0;
							end
							
						end
					end
				
				res = stages[clogb2(g_barrelshift_tb_parampkg::A_Width)];
			end
			3: begin
				stages[0] = trans.a;
				for(int variable_i=1; variable_i<=clogb2(g_barrelshift_tb_parampkg::A_Width); variable_i++) begin
					if(trans.pos[variable_i - 1] == 0) stages[variable_i] = stages[variable_i - 1];
					else begin
						int k;
						for(k=(g_barrelshift_tb_parampkg::A_Width - 2**(variable_i - 1)); k<g_barrelshift_tb_parampkg::A_Width; k++)
							stages[variable_i][k - (g_barrelshift_tb_parampkg::A_Width - 2**(variable_i - 1))] = stages[variable_i - 1][k];
						for(k=0; k<(g_barrelshift_tb_parampkg::A_Width - 2**(variable_i - 1)); k++)
							stages[variable_i][k + (2**(variable_i - 1))] = stages[variable_i - 1][k];
					end
				end
				res = stages[clogb2(g_barrelshift_tb_parampkg::A_Width)];
			end
			4: begin
				stages[0] = trans.a;
				for(int variable_i=1; variable_i<=clogb2(g_barrelshift_tb_parampkg::A_Width); variable_i++) begin
					if(trans.pos[variable_i - 1] == 0) stages[variable_i] = stages[variable_i - 1];
					else begin
						int k;
						for(k=2**(variable_i - 1); k<g_barrelshift_tb_parampkg::A_Width; k++)
							stages[variable_i][k-2**(variable_i - 1)] = stages[variable_i - 1][k];
						for(k=0; k<2**(variable_i - 1); k++)
							stages[variable_i][k+g_barrelshift_tb_parampkg::A_Width-2**(variable_i - 1)] = stages[variable_i - 1][k];
					end
				end
				res = stages[clogb2(g_barrelshift_tb_parampkg::A_Width)];
			end
			5: begin
				
					stages[0] = trans.a;
					for(int variable_i=1; variable_i<=clogb2(g_barrelshift_tb_parampkg::A_Width); variable_i++) begin
						if(trans.pos[variable_i - 1] == 0) stages[variable_i] = stages[variable_i - 1];
						else begin
							int k;
							if(trans.dir == 0) begin
								for(k=(g_barrelshift_tb_parampkg::A_Width - 2**(variable_i - 1)); k<g_barrelshift_tb_parampkg::A_Width; k++)
									stages[variable_i][k - (g_barrelshift_tb_parampkg::A_Width - 2**(variable_i - 1))] = stages[variable_i - 1][k];
								for(k=0; k<(g_barrelshift_tb_parampkg::A_Width - 2**(variable_i - 1)); k++)
									stages[variable_i][k + (2**(variable_i - 1))] = stages[variable_i - 1][k];
							end else begin
								for(k=2**(variable_i - 1); k<g_barrelshift_tb_parampkg::A_Width; k++)
									stages[variable_i][k-2**(variable_i - 1)] = stages[variable_i - 1][k];
								for(k=0; k<2**(variable_i - 1); k++)
									stages[variable_i][k+g_barrelshift_tb_parampkg::A_Width-2**(variable_i - 1)] = stages[variable_i - 1][k];
							end
							
						end
					end
				
				res = stages[clogb2(g_barrelshift_tb_parampkg::A_Width)];
			end
			endcase

			if(res == trans.z_sig) $display("Result is as Expected (%0d:%0d)\n", no_transactions-no_errors, no_transactions);
			else $error("WRONG#%0d!\n\tExpected: %0b Actual: %0b\n",++no_errors, res, trans.z_sig);

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

module g_barrelshift_tbench_top;
	bit clk;
	bit reset;

	always #5 clk = ~clk;

	initial begin
		reset = 1;
		#5 reset = 0;
	end

	intf i_intf(clk,reset);
	test t1(i_intf);
   
	g_barrelshift #(
		.Latency(g_barrelshift_tb_parampkg::Latency),
		.Direction(g_barrelshift_tb_parampkg::Direction),
		.Input_Width(g_barrelshift_tb_parampkg::A_Width),
		.Enable_Port(g_barrelshift_tb_parampkg::Enable_Port)
		) DUT (
			.CLK(i_intf.clk),
			.EN(i_intf.en),
			.A_SIG(i_intf.a),
			.SHIFTPOS(i_intf.pos),
			.SHIFTDIR(i_intf.dir),
			.Z_SIG(i_intf.z_sig)
		);
   
	initial begin
		$dumpfile("dump.vcd"); $dumpvars;
	end
endmodule
