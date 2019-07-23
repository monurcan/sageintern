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

entity G_ROM is
    Generic(
           ROM_WIDTH		: integer range 1 to 256  := 32;
           ROM_DEPTH 		: integer range 1 to 65536:= 1024;
           DATA_FILE 		: string                  := "C:\Users\agunesen\Desktop\ROM_Data.txt"; 
    	   Enable_Port 		: boolean                 := TRUE;
           Latency 			: integer range 0 to 256  := 4);
    Port ( CLK 				: in STD_LOGIC;
           EN				: in STD_LOGIC;
           ADDR 			: in STD_LOGIC_VECTOR (clogb2(ROM_DEPTH)-1 downto 0);    
           DOUT 			: out STD_LOGIC_VECTOR (ROM_WIDTH-1 downto 0));   
end G_ROM;

architecture RTL of G_ROM is

type t_rom is array (0 to ROM_DEPTH-1) of std_logic_vector (ROM_WIDTH-1 downto 0);
type t_pipe is array(0 to Latency -1) of std_logic_vector(ROM_WIDTH-1 downto 0);

	function initramfromfile (
	ramfilename : in string; 
	r_width 	: in integer; 
	r_depth 	: in integer) return t_rom is
	
	file ramfile			: text is in ramfilename;
	variable v_ramfileline 	: line;
	variable v_ram_name		: t_rom;
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
	r_depth 	: in integer) return t_rom is
	
	variable v_ram_name_0	: t_rom;
    begin
        
        if ramfile = "All zeros" then
            v_ram_name_0 := (others => (others => '0'));            
        else
            v_ram_name_0 := InitRamFromFile(ramfile, r_width, r_depth) ;
        end if;
		return v_ram_name_0;
    end;

signal Enable_inside	: STD_LOGIC := '1';
signal SP_ROM 			: t_rom:= init_from_file_or_zeroes(DATA_FILE, ROM_WIDTH, ROM_DEPTH);
signal Rom_Data			: STD_LOGIC_VECTOR (ROM_WIDTH-1 downto 0);
signal pipe_reg         : t_pipe;  -- Pipelines for Memory

begin

if_NE: if(Enable_Port = FALSE) generate     
    Enable_inside <= '1';
end generate if_NE;
if_E: if(Enable_Port = TRUE) generate      
    Enable_inside <= EN;
end generate if_E;

Rom_Data <= SP_ROM(to_integer(unsigned(ADDR)));

No_Latency: if(Latency = 0) generate
	DOUT <= Rom_Data;
end generate No_Latency;

Lat: if(Latency > 0) generate									-- Output data goes to first stage of latency pipe
	pr_pipe_in:process(CLK)									
	begin									          
		if(CLK'event and CLK = '1') then
			if(Enable_Inside = '1') then
				pipe_reg(0) <= Rom_Data;
			end if;
		end if;
	end process pr_pipe_in;
end generate Lat;

Lat_1: if(Latency = 1) generate
	   DOUT <= pipe_reg(0);
end generate Lat_1; 

Lat_out: if(Latency > 1) generate									-- Output data goes through pipe
	pr_pipe:process(CLK)									
	begin										
		if(CLK'event and CLK = '1') then
			if(Enable_Inside = '1') then
			    pipe_reg(1 to Latency-1) <= pipe_reg(0 to Latency-2);
			end if;
		end if;
	end process pr_pipe;
	DOUT <= pipe_reg(Latency-1);
end generate Lat_out;

end RTL;
