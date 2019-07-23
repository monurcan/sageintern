----------------------------------------------------------------------------------
-- Company: TUBITAK SAGE
-- Engineer: Adem GUNESEN
-- 
-- Create Date: 01.04.2019 16:07:19
-- Design Name: Relational
-- Module Name: G_RELATIONAL - RTL
-- Project Name: Relational
-- Target Devices: Unconstrained
-- Tool Versions: Vivado 2016.3
-- Description: A generic relational logic implementation based on System Generator Relational block
--              for A=B, A!=B, A>B, A<B, A>=B, A<=B conditions.
--              Output Z_SIG = 1 if the specified condition holds.
-- Dependencies: None
-- 
-- Revision: 1
-- Revision 0.01 - File Created
-- Additional Comments: --
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use std.textio.all;
use IEEE.NUMERIC_STD.ALL;
use work.P_SAGE_LIB.all;


entity G_SIMPLEDPRAM is
    Generic(
           RAM_WIDTH		: integer range 1 to 256	:= 32;
           RAM_DEPTH 		: integer range 1 to 65536	:= 1024;
           INIT_FILE 		: string 					:= "All zeros"; 
           --Simple_or_True: integer := 0;
           --Write_Mode: integer := 0;
           Two_CLK			: boolean 					:= false;
           Reset_Port_B 	: boolean 					:= FALSE;
           Enable_Port_B 	: boolean 					:= FALSE;
           Latency          : integer range 1 to 256    := 2);
    Port ( CLK_A 			: in STD_LOGIC;
           CLK_B 			: in STD_LOGIC;
           RST_B 			: in STD_LOGIC;
		   EN_WA 			: in STD_LOGIC;
           EN_B 			: in STD_LOGIC;
           ADDR_A 			: in STD_LOGIC_VECTOR (clogb2(RAM_DEPTH)-1 downto 0); 
           ADDR_B 			: in STD_LOGIC_VECTOR (clogb2(RAM_DEPTH)-1 downto 0); 
           DATA_A 			: in STD_LOGIC_VECTOR (RAM_WIDTH-1 downto 0);      
           DOUT_B 			: out STD_LOGIC_VECTOR (RAM_WIDTH-1 downto 0));   
end G_SIMPLEDPRAM;

architecture RTL of G_SIMPLEDPRAM is

type t_ram is array (0 to RAM_DEPTH -1) of std_logic_vector(RAM_WIDTH-1 downto 0);
type t_pipe is array(0 to Latency -1) of std_logic_vector(RAM_WIDTH-1 downto 0);

	function initramfromfile (
	ramfilename : in string; 
	r_width 	: in integer; 
	r_depth 	: in integer) return t_ram is
	
	file ramfile			: text is in ramfilename;
	variable v_ramfileline 	: line;
	variable v_ram_name		: t_ram;
	variable v_bitvec 		: bit_vector(r_width-1 downto 0);
	begin
		for v_i in 0 to r_depth - 1 loop
			readline (ramfile, v_ramfileline);
			read (v_ramfileline, v_bitvec);
			v_ram_name(v_i) := to_stdlogicvector(v_bitvec);
		end loop;
		return v_ram_name;
	end function;
	
	
	function init_from_file_or_zeroes(
	ramfile 	: in string; 
	r_width 	: in integer; 
	r_depth 	: in integer) return t_ram is
	
	variable v_ram_name_0	: t_ram;
    begin
        
        if ramfile = "All zeros" then
            v_ram_name_0 := (others => (others => '0'));            
        else
            v_ram_name_0 := InitRamFromFile(ramfile, r_width, r_depth) ;
        end if;
		return v_ram_name_0;
    end;

signal douta_reg 	    : std_logic_vector(RAM_WIDTH-1 downto 0) := (others => '0');       
signal doutb_reg 	    : std_logic_vector(RAM_WIDTH-1 downto 0) := (others => '0'); 
signal SP_RAM 			: t_ram
						:= init_from_file_or_zeroes(INIT_FILE, RAM_WIDTH, RAM_DEPTH);
signal Ram_Data		    : std_logic_vector(RAM_WIDTH-1 downto 0) ;
signal Reset_B		    : STD_LOGIC := '0';
signal Enable_inside_B  : STD_LOGIC := '1';
signal pipe_reg         : t_pipe;                             -- Pipelines for Memory

begin


if_NE: if(Enable_Port_B = FALSE) generate     
    Enable_inside_B <= '1';
end generate if_NE;
if_E: if(Enable_Port_B = TRUE) generate      
    Enable_inside_B <= EN_B;
end generate if_E;

if_NR: if(Reset_Port_B = FALSE) generate     
    Reset_B <= '0';
end generate if_NR;
if_R: if(Reset_Port_B = TRUE) generate     
    Reset_B <= RST_B;
end generate if_R;

if_1_CLK: if(Two_CLK = FALSE) generate													--1 clock ram, write from A port, read from  B port
    pr_clk_1_wr:process(CLK_A)															
    begin
        if(CLK_A'event and CLK_A = '1') then
            if(EN_WA = '1') then
                SP_RAM(to_integer(unsigned(ADDR_A))) <= DATA_A;
            end if;
            if(Enable_inside_B = '1') then
                Ram_Data <= SP_RAM(to_integer(unsigned(ADDR_B)));
            end if;
        end if;
    end process pr_clk_1_wr;
end generate;

if_2_CLK: if(Two_CLK = TRUE) generate													--2 clock ram, write from A port
    pr_clk_2_w:process(CLK_A)																
    begin
        if(CLK_A'event and CLK_A = '1') then
            if(EN_WA = '1') then
                SP_RAM(to_integer(unsigned(ADDR_A))) <= DATA_A;
            end if;
        end if;
    end process pr_clk_2_w;
    
    																					--2 clock ram, read from B port
    pr_clk_2_r:process(CLK_B)									
    begin									
        if(CLK_B'event and CLK_B = '1') then
            if(Enable_inside_B = '1') then
                Ram_Data <= SP_RAM(to_integer(unsigned(ADDR_B)));
            end if;
        end if;
    end process pr_clk_2_r;
end generate;


	
if_1_CLK_Lat: if(Two_CLK = FALSE) generate    
	No_Latency_B: if(Latency = 1) generate
    DOUT_B <= Ram_Data;
    end generate No_Latency_B;
    Lat_B: if(Latency > 1) generate									-- Output data goes to first stage of latency pipe
        pr_pipe_in:process(CLK_A)									
        begin									          
            if(CLK_A'event and CLK_A = '1') then
				if(Reset_B = '1') then
					pipe_reg(0) <= (others => '0');
				else
	                if(Enable_Inside_B = '1') then
	                    pipe_reg(0) <= Ram_Data;
	                end if;
				end if;
            end if;
        end process pr_pipe_in;
    end generate Lat_B;
    

    Lat_1_B: if(Latency = 2) generate
           DOUT_B <= pipe_reg(0);
    end generate Lat_1_B; 

    Lat_out_B: if(Latency > 2) generate									-- Output data goes through pipe
        pr_pipe:process(CLK_A)									
        begin										
          if(CLK_A'event and CLK_A = '1') then
		  	if(Reset_B = '1') then
				for i in 0 to Latency-2 loop
					pipe_reg(i+1) <= (others => '0');
				end loop;
			else
	            if(Enable_Inside_B = '1') then
	                for i in 0 to Latency-2 loop
	                    pipe_reg(i+1) <= pipe_reg(i);
	                end loop;
	            end if;
			end if;
          end if;
        end process pr_pipe;
        DOUT_B <= pipe_reg(Latency-2);
    end generate Lat_out_B;
end generate if_1_CLK_Lat;

if_2_CLK_Lat: if(Two_CLK = TRUE) generate    
    Lat_B: if(Latency > 1) generate									-- Output data goes to first stage of latency pipe
        pr_pipe_in:process(CLK_B)									
        begin									          
            if(CLK_B'event and CLK_B = '1') then
				if(Reset_B = '1') then
					pipe_reg(0) <= (others => '0');
				else
	                if(Enable_Inside_B = '1') then
	                    pipe_reg(0) <= Ram_Data;
	                end if;
				end if;
            end if;
        end process pr_pipe_in;
    end generate Lat_B;
    

    Lat_1_B: if(Latency = 2) generate
           DOUT_B <= pipe_reg(0);
    end generate Lat_1_B; 

    Lat_out_B: if(Latency > 2) generate									-- Output data goes through pipe
        pr_pipe:process(CLK_B)									
        begin										
          if(CLK_B'event and CLK_B = '1') then
		  	if(Reset_B = '1') then
					pipe_reg(1 to Latency-1) <= (others=>(others => '0'));
			else
	            if(Enable_Inside_B = '1') then
	                    pipe_reg(1 to Latency-1) <= pipe_reg(0 to Latency-2);
	            end if;
			end if;
          end if;
        end process pr_pipe;
        DOUT_B <= pipe_reg(Latency-2);
    end generate Lat_out_B;
end generate if_2_CLK_Lat;

end RTL;