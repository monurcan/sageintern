`include "p_memfuncs.sv"

interface intf(input logic clk, reset);
	logic en, EN_W;
	logic [(clogb2(g_simpledpram_tb_parampkg::RAM_DEPTH)-1):0] ADDR;

	logic [(g_simpledpram_tb_parampkg::RAM_WIDTH-1):0] DOUT, DATA;
endinterface

class transaction;
	rand bit [(clogb2(g_simpledpram_tb_parampkg::RAM_DEPTH)-1):0] ADDR;
	constraint C {ADDR < g_simpledpram_tb_parampkg::RAM_DEPTH;}

	bit en, EN_W, reset;

	bit [(g_simpledpram_tb_parampkg::RAM_WIDTH-1):0] DOUT;
	rand bit [(g_simpledpram_tb_parampkg::RAM_WIDTH-1):0] DATA;

	function void display(string name);
		$display("-------------------------");
		$display("- %s ",name);
		$display("-------------------------");
		$display("- addr=%0d, data=%0d, EN_W=%0b", ADDR, DATA, EN_W);
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
		// read all the ADDRes
		coverpoint vif.ADDR {
			bins legit[g_simpledpram_tb_parampkg::RAM_DEPTH/10] = {[1:g_simpledpram_tb_parampkg::RAM_DEPTH]};
		}
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
		vif.ADDR <= 0;
		vif.DATA <= 0;
		vif.en <= 0;
		vif.EN_W <= 0;
		//    $display("[ DRIVER ] ----- Reset Ended   -----");
	endtask

	task main;
		forever begin
			transaction trans;
			gen2driv.get(trans);
			repeat(10)
			@(posedge vif.clk);
			vif.en <= 1;
			vif.EN_W <= 1;
			vif.ADDR <= trans.ADDR;
			vif.DATA <= trans.DATA;
			@(posedge vif.clk);
			vif.en <= 0;
			vif.EN_W <= 0;
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
			trans.ADDR = vif.ADDR;
			trans.DATA = vif.DATA;
			trans.en = vif.en;
			trans.reset = vif.reset;
			trans.EN_W = vif.EN_W;

			trans.DOUT = vif.DOUT;

			//@(posedge vif.clk);
			mon2scb.put(trans);
			// trans.display("[ Monitor ]");
		end
	endtask
endclass

typedef bit[(g_simpledpram_tb_parampkg::RAM_WIDTH-1):0] t_ram[(g_simpledpram_tb_parampkg::RAM_DEPTH-1):0];

function t_ram initramfsimpledpramfile (input string ramfilename, integer r_width, integer r_depth);
	automatic int ramfile = $fopen(ramfilename, "r");
	t_ram v_ram_name;
		for(int v_i=0; v_i<r_depth; v_i++)
		$fscanf(ramfile, "%b", v_ram_name[v_i]);
		return v_ram_name;
endfunction

function t_ram init_fsimpledpram_file_or_zeroes(input string ramfile, integer r_width, integer r_depth);
	t_ram v_ram_name_0;
	        if(ramfile != "All zeros")
            v_ram_name_0 = initramfsimpledpramfile(ramfile, r_width, r_depth);
		return v_ram_name_0;
endfunction

t_ram SP_RAM = init_fsimpledpram_file_or_zeroes(g_simpledpram_tb_parampkg::INIT_FILE, g_simpledpram_tb_parampkg::RAM_WIDTH, g_simpledpram_tb_parampkg::RAM_DEPTH);

int no_transactionsA, no_errorsA=0, no_transactionsB, no_errorsB=0;

class scoreboardA;
	mailbox mon2scb;

	typedef bit[(g_simpledpram_tb_parampkg::RAM_WIDTH-1):0] t_pipe[(g_simpledpram_tb_parampkg::Latency-1):0];

	function new(mailbox mon2scb);
		this.mon2scb = mon2scb;
	endfunction

	task main;
		transaction trans;

		bit[(g_simpledpram_tb_parampkg::RAM_WIDTH-1):0] pre_DOUT, Ram_Data, DOUT;
		t_pipe pipe_reg;
		bit Enable_inside, Reset;

		forever begin
			mon2scb.get(trans);
			trans.display("[ ScoreboardA ]");

			Enable_inside = g_simpledpram_tb_parampkg::Enable_Port_A ? trans.en : 1;
			Reset = g_simpledpram_tb_parampkg::Reset_Port_A ? trans.reset : 1;

			
				if(g_simpledpram_tb_parampkg::Write_Mode == 0)
					if(Enable_inside)
						if(trans.EN_W) begin
							SP_RAM[trans.ADDR] = trans.DATA;
							Ram_Data = trans.DATA;
						end else
							Ram_Data = SP_RAM[trans.ADDR];

				if(g_simpledpram_tb_parampkg::Write_Mode == 1)
					if(Enable_inside) begin
						if(trans.EN_W)
							SP_RAM[trans.ADDR] = trans.DATA;

						Ram_Data = SP_RAM[trans.ADDR];
					end

				if(g_simpledpram_tb_parampkg::Write_Mode == 2)
					if(Enable_inside)
						if(trans.EN_W) SP_RAM[trans.ADDR] = trans.DATA;
						else Ram_Data = SP_RAM[trans.ADDR];

			if(g_simpledpram_tb_parampkg::Latency == 1) DOUT = Ram_Data;
			if(g_simpledpram_tb_parampkg::Latency == 2) DOUT = pipe_reg[0];
			
			if(DOUT == trans.DOUT); //$display("Result is as Expected (%0d:%0d)\n", no_transactions-no_errors, no_transactions);
			else if((no_transactionsA-10)%11) ++no_errorsA; //$error("WRONG#%0d!\n\tExpected: %0d Actual: %0d\n",++no_errors, DOUT, trans.DOUT);
			if(g_simpledpram_tb_parampkg::Latency > 2) DOUT = pipe_reg[g_simpledpram_tb_parampkg::Latency-2];

			if(g_simpledpram_tb_parampkg::Latency > 1)
				if(Reset)
					pipe_reg[0] = '0;
				else if(Enable_inside) pipe_reg[0] = Ram_Data;

			if(g_simpledpram_tb_parampkg::Latency > 2) begin
				if(Reset)
					for(int i = 1; i < g_simpledpram_tb_parampkg::Latency; i++)
						pipe_reg[i] = '0;
				else begin
					if(Enable_inside)
						pipe_reg[(g_simpledpram_tb_parampkg::Latency-1):1] = pipe_reg[(g_simpledpram_tb_parampkg::Latency-2):0];
				end
			end
			no_transactionsA++;
		end
	endtask
endclass

class scoreboardB;
	mailbox mon2scb;

	typedef bit[(g_simpledpram_tb_parampkg::RAM_WIDTH-1):0] t_pipe[(g_simpledpram_tb_parampkg::Latency-1):0];

	function new(mailbox mon2scb);
		this.mon2scb = mon2scb;
	endfunction


	task main;
		transaction trans;

		bit[(g_simpledpram_tb_parampkg::RAM_WIDTH-1):0] pre_DOUT, Ram_Data, DOUT;
		t_pipe pipe_reg;
		bit Enable_inside, Reset;

		forever begin
			mon2scb.get(trans);
			trans.display("[ ScoreboardB ]");

			Enable_inside = g_simpledpram_tb_parampkg::Enable_Port_B ? trans.en : 1;
			Reset = g_simpledpram_tb_parampkg::Reset_Port_B ? trans.reset : 1;

			
				if(g_simpledpram_tb_parampkg::Write_Mode == 0)
					if(Enable_inside)
						if(trans.EN_W) begin
							SP_RAM[trans.ADDR] = trans.DATA;
							Ram_Data = trans.DATA;
						end else
							Ram_Data = SP_RAM[trans.ADDR];

				if(g_simpledpram_tb_parampkg::Write_Mode == 1)
					if(Enable_inside) begin
						if(trans.EN_W)
							SP_RAM[trans.ADDR] = trans.DATA;

						Ram_Data = SP_RAM[trans.ADDR];
					end

				if(g_simpledpram_tb_parampkg::Write_Mode == 2)
					if(Enable_inside)
						if(trans.EN_W) SP_RAM[trans.ADDR] = trans.DATA;
						else Ram_Data = SP_RAM[trans.ADDR];


			if(g_simpledpram_tb_parampkg::Latency == 1) DOUT = Ram_Data;
			if(g_simpledpram_tb_parampkg::Latency == 2) DOUT = pipe_reg[0];
			
			if(DOUT == trans.DOUT); //$display("Result is as Expected (%0d:%0d)\n", no_transactions-no_errors, no_transactions);
			else if((no_transactionsB-10)%11) ++no_errorsB; //$error("WRONG#%0d!\n\tExpected: %0d Actual: %0d\n",++no_errors, DOUT, trans.DOUT);
			if(g_simpledpram_tb_parampkg::Latency > 2) DOUT = pipe_reg[g_simpledpram_tb_parampkg::Latency-2];

			if(g_simpledpram_tb_parampkg::Latency > 1)
				if(Reset)
					pipe_reg[0] = '0;
				else if(Enable_inside) pipe_reg[0] = Ram_Data;

			if(g_simpledpram_tb_parampkg::Latency > 2) begin
				if(Reset)
					for(int i = 1; i < g_simpledpram_tb_parampkg::Latency; i++)
						pipe_reg[i] = '0;
				else begin
					if(Enable_inside)
						pipe_reg[(g_simpledpram_tb_parampkg::Latency-1):1] = pipe_reg[(g_simpledpram_tb_parampkg::Latency-2):0];
				end
			end
			no_transactionsB++;
		end
	endtask
endclass

class environmentA;
	generator  gen;
	driver     driv;
//	monitor    mon;
//	scoreboardA scb;

	mailbox gen2driv;
//	mailbox mon2scb;

	virtual intf vif;

	function new(virtual intf vif);
		this.vif = vif;

		gen2driv = new();
//		mon2scb  = new();

		gen  = new(gen2driv);
		driv = new(vif,gen2driv);
//		mon  = new(vif,mon2scb);
//		scb  = new(mon2scb);
	endfunction
	task pre_test();
		driv.reset();
	endtask
	task test();
		fork
			gen.main();
			driv.main();
//			mon.main();
//			scb.main();
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

program testA(intf intf);
	environmentA env;

	initial begin
		env = new(intf);
		env.run();
	end
endprogram

class environmentB;
	generator  gen;
	driver     driv;
	monitor    mon;
	scoreboardB scb;

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

program testB(intf intf);
	environmentB env;

	initial begin
		env = new(intf);
		env.run();
	end
endprogram

module g_simpledpram_tbench_top;
	bit clkA, clkB, CLKB;
	bit reset;

	initial begin
		reset = 1;
		#10 reset = 0;
	end

	always #5 clkA++;
	always #7 clkB++;
	
	// TEST FOR PORT A
	intf i_intfA(clkA,reset);
	testA t1(i_intfA);

	// TEST FOR PORT B
	assign CLKB = g_simpledpram_tb_parampkg::Two_CLK ? clkB : clkA;
	intf i_intfB(CLKB,reset);
	testB t2(i_intfB);

	always #10 $display("*** %0d :  %0d  ***", no_transactionsB+no_transactionsA-(no_errorsA+no_errorsB), no_transactionsB+no_transactionsA);

	g_simpledpram #(	
			.RAM_WIDTH(g_simpledpram_tb_parampkg::RAM_WIDTH),
			.RAM_DEPTH(g_simpledpram_tb_parampkg::RAM_DEPTH),
			.INIT_FILE(g_simpledpram_tb_parampkg::INIT_FILE),
			.Two_CLK(g_simpledpram_tb_parampkg::Two_CLK),
			
			.Latency(g_simpledpram_tb_parampkg::Latency),

			.Enable_Port_B(g_simpledpram_tb_parampkg::Enable_Port_B),
			.Reset_Port_B(g_simpledpram_tb_parampkg::Reset_Port_B)
		) DUT (
			.CLK_A(i_intfA.clk),
			.EN_WA(i_intfA.EN_W),
			.ADDR_A(i_intfA.ADDR),
			.DATA_A(i_intfA.DATA),
			.CLK_B(i_intfB.clk),
			.RST_B(i_intfB.reset),
			.EN_B(i_intfB.en),
			.ADDR_B(i_intfB.ADDR),
			.DOUT_B(i_intfB.DOUT)
		);
endmodule

