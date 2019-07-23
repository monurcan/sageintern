
`include "p_memfuncs.sv"

interface intf(input logic clk, reset);
	logic en, EN_WR, EN_RD;
	logic [(g_fifo_tb_parampkg::FIFO_WIDTH-1):0] D_IN;

	logic [(g_fifo_tb_parampkg::FIFO_WIDTH-1):0] DOUT;
	logic [(clogb2(g_fifo_tb_parampkg::FIFO_DEPTH)-1):0] DATA_COUNT;
	logic FULL, EMPTY, A_E, A_F;
endinterface

class transaction;
	rand bit [(g_fifo_tb_parampkg::FIFO_WIDTH-1):0] D_IN;
	rand bit EN_WR, EN_RD;
	constraint C {EN_WR != EN_RD; }
	bit FULL, EMPTY, A_E, A_F;
	bit [(g_fifo_tb_parampkg::FIFO_WIDTH-1):0] DOUT;
	bit [(clogb2(g_fifo_tb_parampkg::FIFO_DEPTH)-1):0] DATA_COUNT;
	bit reset, en;

	function void display(string name);
		$display("-------------------------");
		$display("- %s ",name);
		$display("-------------------------");
		$display("- en=%0b, en_wr=%0b, en_rd=%0b, D_IN=%0d", en, EN_WR, EN_RD, D_IN);
		$display("- DOUT = %0d, DATA_COUNT = %0d, FULL=%0b, EMPTY=%0b, A_E=%0b, A_F=%0b", DOUT, DATA_COUNT, FULL, EMPTY, A_E, A_F);
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
	int no_transactions, data_count=0;
	virtual intf vif;
	mailbox gen2driv;

	covergroup cg;
		coverpoint vif.D_IN;
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
		vif.D_IN <= 0;
		vif.EN_WR <= 0;
		vif.EN_RD <= 0;
		vif.en <= 0;
		//    $display("[ DRIVER ] ----- Reset Ended   -----");
	endtask

	task main;
		transaction trans;
		forever begin
			gen2driv.get(trans);
			repeat(10)
			@(posedge vif.clk);
			vif.en <= 1;
			vif.D_IN <= trans.D_IN;
			
			if(data_count>(g_fifo_tb_parampkg::FIFO_DEPTH-11)) begin
				vif.EN_WR <= 0;
				vif.EN_RD <= 1;
			end else if(data_count<11) begin
				vif.EN_RD <= 0;
				vif.EN_WR <= 1;
			end else begin
				vif.EN_RD <= trans.EN_RD;
				vif.EN_WR <= trans.EN_WR;
			end

			@(posedge vif.clk);
			vif.en <= 0;
			//trans.DOUT = vif.DOUT;
		
			cg.sample();
			coverage = cg.get_inst_coverage();
			if(this.get_coverage()==100) begin -> covered; return; end

			//@(posedge vif.clk);
			//      trans.display("[ Driver ]");
			no_transactions++;
		end
	endtask

	task counter;
		forever @(negedge vif.clk) begin
			if(vif.EN_WR) data_count++;
			if(vif.EN_RD) data_count--;
			if(vif.reset) data_count=0;
			//$display("dataonur%0d",data_count);
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
			trans.D_IN = vif.D_IN;
			trans.EN_WR = vif.EN_WR;
			trans.EN_RD = vif.EN_RD;
			trans.en = vif.en;
			trans.reset = vif.reset;

			trans.DOUT = vif.DOUT;
			trans.FULL = vif.FULL;
			trans.EMPTY = vif.EMPTY;
			trans.DATA_COUNT = vif.DATA_COUNT;
			trans.A_E = vif.A_E;
			trans.A_F = vif.A_F;

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
		
		typedef bit[(g_fifo_tb_parampkg::FIFO_WIDTH-1):0] t_ram[(g_fifo_tb_parampkg::FIFO_DEPTH-1):0];
		t_ram r_FIFO_DATA;
		integer r_WR_INDEX=0, r_RD_INDEX=0, r_FIFO_COUNT=0;
		bit w_FULL, w_EMPTY, Reset, Enable_inside, FULL, EMPTY, A_E, A_F;
		bit[(g_fifo_tb_parampkg::FIFO_WIDTH-1):0] DOUT_REG, DOUT;
		bit[(clogb2(g_fifo_tb_parampkg::FIFO_DEPTH)-1):0] DATA_COUNT;

		forever begin
			mon2scb.get(trans);
			trans.display("[ Scoreboard ]");

			Enable_inside = g_fifo_tb_parampkg::Enable_Port ? trans.en : 1;
			Reset = g_fifo_tb_parampkg::Reset_Port ? trans.reset : 0;

			if(Reset) begin
				r_FIFO_COUNT = 0;
				r_WR_INDEX   = 0;
				r_RD_INDEX   = 0;
			end else if(Enable_inside) begin
				if(trans.EN_WR && !trans.EN_RD)
					r_FIFO_COUNT = r_FIFO_COUNT + 1;
				else if(!trans.EN_WR && trans.EN_RD)
					r_FIFO_COUNT = r_FIFO_COUNT - 1;

				if(trans.EN_WR && !w_FULL)
					if (r_WR_INDEX == (g_fifo_tb_parampkg::FIFO_DEPTH-1))
						r_WR_INDEX = 0;
					else
						r_WR_INDEX = r_WR_INDEX + 1;

				if(trans.EN_RD && !w_EMPTY)
					if (r_RD_INDEX == (g_fifo_tb_parampkg::FIFO_DEPTH-1))
						r_RD_INDEX = 0;
					else
						r_RD_INDEX = r_RD_INDEX + 1;

				if(trans.EN_WR)
					r_FIFO_DATA[r_WR_INDEX] = trans.D_IN;
			end

			if(!g_fifo_tb_parampkg::FWFT) begin
				if (trans.EN_RD && !w_EMPTY)
					DOUT_REG = r_FIFO_DATA[r_RD_INDEX];

				DOUT = DOUT_REG;
			end

			if(g_fifo_tb_parampkg::FWFT)
				DOUT = r_FIFO_DATA[r_RD_INDEX];

			w_FULL  = (r_FIFO_COUNT == g_fifo_tb_parampkg::FIFO_DEPTH) ? 1 : 0;
			w_EMPTY = (r_FIFO_COUNT==0) ? 1 : 0;
			FULL  = w_FULL;
			EMPTY = w_EMPTY;

			if(g_fifo_tb_parampkg::Data_Count_Port)
				DATA_COUNT = r_FIFO_COUNT;

			if(g_fifo_tb_parampkg::Almost_Full_Port)
				A_F = (r_FIFO_COUNT >= g_fifo_tb_parampkg::Almost_Full_Treshold) ? 1 : 0;

			if(g_fifo_tb_parampkg::Almost_Empty_Port)
				A_E = (r_FIFO_COUNT <= g_fifo_tb_parampkg::Almost_Empty_Treshold) ? 1 : 0;

			if((DOUT == trans.DOUT) && (FULL == trans.FULL) && (EMPTY == trans.EMPTY) && (DATA_COUNT == trans.DATA_COUNT) && (A_E == trans.A_E) && (A_F == trans.A_F)) $display("Result is as Expected (%0d:%0d)\n", no_transactions-no_errors, no_transactions);
				else $error("WRONG#%0d!\n\tExpected: DOUT:%0d, FULL:%1b, EMPTY:%1b, DATA_COUNT:%0d, A_E:%1b, A_F:%1b Actual: DOUT:%0d, FULL:%1b, EMPTY:%1b, DATA_COUNT:%0d, A_E:%1b, A_F:%1b\n",++no_errors, DOUT, FULL, EMPTY, DATA_COUNT, A_E, A_F, trans.DOUT, trans.FULL, trans.EMPTY, trans.DATA_COUNT, trans.A_E, trans.A_F);

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
			driv.counter();
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

module g_fifo_tbench_top;
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
   
	g_fifo #(
			.FIFO_WIDTH(g_fifo_tb_parampkg::FIFO_WIDTH),
			.FIFO_DEPTH(g_fifo_tb_parampkg::FIFO_DEPTH),
			.Enable_Port(g_fifo_tb_parampkg::Enable_Port),
			.Reset_Port(g_fifo_tb_parampkg::Reset_Port),
			.FWFT(g_fifo_tb_parampkg::FWFT),
			.Data_Count_Port(g_fifo_tb_parampkg::Data_Count_Port),
			.Almost_Empty_Port(g_fifo_tb_parampkg::Almost_Empty_Port),
			.Almost_Empty_Treshold(g_fifo_tb_parampkg::Almost_Empty_Treshold),
			.Almost_Full_Port(g_fifo_tb_parampkg::Almost_Full_Port),
			.Almost_Full_Treshold(g_fifo_tb_parampkg::Almost_Full_Treshold)
		) DUT (
			.CLK(i_intf.clk),
			.EN(i_intf.en),
			.RST(i_intf.reset),
			.EN_WR(i_intf.EN_WR),
			.FULL(i_intf.FULL),
			.EN_RD(i_intf.EN_RD),
			.D_IN(i_intf.D_IN),
			.DOUT(i_intf.DOUT),
			.EMPTY(i_intf.EMPTY),
			.DATA_COUNT(i_intf.DATA_COUNT),
			.A_E(i_intf.A_E),
			.A_F(i_intf.A_F)
		);
endmodule
