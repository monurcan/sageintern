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

entity G_SPRAM is
    Generic(
           RAM_WIDTH		: integer range 1 to 256  := 4;
           RAM_DEPTH 		: integer range 1 to 65536:= 32;
           INIT_FILE 		: string                  := "C:\Users\agunesen\Desktop\Ram_Initial_Data.dat"; 
           Memory_Type		: integer range 0 to 1    := 0;
           Write_Mode		: integer range 0 to 2    := 0;
		   Reset_Port 		: boolean                 := TRUE;
    	   Enable_Port 		: boolean                 := TRUE;
           Latency 			: integer range 1 to 256  := 1);
    Port ( CLK 				: in STD_LOGIC;
           RST 				: in STD_LOGIC;
           EN 				: in STD_LOGIC;
		   EN_W 			: in STD_LOGIC;
           ADDR 			: in STD_LOGIC_VECTOR (clogb2(RAM_DEPTH)-1 downto 0); 
           DATA 			: in STD_LOGIC_VECTOR (RAM_WIDTH-1 downto 0);      
           DOUT 			: out STD_LOGIC_VECTOR (RAM_WIDTH-1 downto 0));   
end G_SPRAM;

architecture RTL of G_SPRAM is

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


signal douta_reg 		: std_logic_vector(RAM_WIDTH-1 downto 0) := (others => '0');

signal SP_RAM 			: t_ram
						:= init_from_file_or_zeroes(INIT_FILE, RAM_WIDTH, RAM_DEPTH);
signal Ram_Data 		: std_logic_vector(RAM_WIDTH-1 downto 0) ;
signal Reset			: STD_LOGIC := '0';
signal Enable_inside	: STD_LOGIC := '1';
signal pre_DOUT			: std_logic_vector(RAM_WIDTH-1 downto 0) := (others => '0'); 

signal pipe_reg         : t_pipe;  -- Pipelines for Memory

begin

if_NE: if(Enable_Port = FALSE) generate     
    Enable_inside <= '1';
end generate if_NE;
if_E: if(Enable_Port = TRUE) generate      
    Enable_inside <= EN;
end generate if_E;

if_NR: if(Reset_Port = FALSE) generate     
    Reset <= '0';
end generate if_NR;
if_R: if(Reset_Port = TRUE) generate     
    Reset <= RST;
end generate if_R;
 

if_B: if(Memory_Type = 0) generate
    if_Mode_0:if(Write_Mode = 0) generate       --Read after write
    pr_w0:process(CLK)
    begin
        if(CLK'event and CLK = '1') then
            if(Enable_inside = '1') then
                if(EN_W = '1') then
                    SP_RAM(to_integer(unsigned(ADDR))) <= DATA;
                    Ram_Data <= DATA;
                else
                    Ram_Data <= SP_RAM(to_integer(unsigned(ADDR)));
                end if;
            end if;
        end if;
    end process pr_w0;
    end generate;
    
    if_Mode_1:if(Write_Mode = 1) generate       --Read before write
    pr_w1:process(CLK)
    begin
        if(CLK'event and CLK = '1') then
            if(Enable_inside = '1') then
                if(EN_W = '1') then
                    SP_RAM(to_integer(unsigned(ADDR))) <= DATA;
                end if;
                Ram_Data <= SP_RAM(to_integer(unsigned(ADDR)));
            end if;
        end if;
    end process pr_w1;
    end generate;
    
    if_Mode_2:if(Write_Mode = 2) generate       --No read on write
    pr_w2:process(CLK)
    begin
        if(CLK'event and CLK = '1') then
            if(Enable_inside = '1') then
                if(EN_W = '1') then
                    SP_RAM(to_integer(unsigned(ADDR))) <= DATA;
                else
                    Ram_Data <= SP_RAM(to_integer(unsigned(ADDR)));
                end if;
            end if;
        end if;
    end process pr_w2;
    end generate;
end generate;

if_D: if(Memory_Type = 1) generate
    if_Mode_3:if(Write_Mode = 0) generate       --No read on write
    pr_d:process(CLK)								
    begin
        if(CLK'event and CLK = '1') then
            if(EN_W = '1') then
                SP_RAM(to_integer(unsigned(ADDR))) <= DATA;
            end if;
        end if;
    end process pr_d;
    
    Ram_Data <= SP_RAM(to_integer(unsigned(ADDR)));
    end generate;
end generate;

	No_Latency: if(Latency = 1) generate
        DOUT <= Ram_Data;
    end generate No_Latency;
    
    Lat: if(Latency > 1) generate									-- Output data goes to first stage of latency pipe
        pr_pipe_in:process(CLK)									
        begin									          
            if(CLK'event and CLK = '1') then
				if(Reset = '1') then
					pipe_reg(0) <= (others => '0');
				else
	                if(Enable_Inside = '1') then
	                    pipe_reg(0) <= Ram_Data;
	                end if;
				end if;
            end if;
        end process pr_pipe_in;
    end generate Lat;
    
    Lat_1: if(Latency = 2) generate
           DOUT <= pipe_reg(0);
    end generate Lat_1; 

    Lat_out: if(Latency > 2) generate									-- Output data goes through pipe
        pr_pipe:process(CLK)									
        begin										
          if(CLK'event and CLK = '1') then
		  	if(Reset = '1') then
					pipe_reg(1 to Latency-1) <= (others=>(others => '0'));
			else
	            if(Enable_Inside = '1') then
                    pipe_reg(1 to Latency-1) <= pipe_reg(0 to Latency-2);
	            end if;
			end if;
          end if;
        end process pr_pipe;
        DOUT <= pipe_reg(Latency-2);
    end generate Lat_out;


end RTL;
