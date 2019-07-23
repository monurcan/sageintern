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
use IEEE.NUMERIC_STD.ALL;
use work.P_SAGE_LIB.all;

entity G_ADDSHIFTREG is
    Generic(
            Max_Latency		: integer range 2 to 1024	:= 3;
            Width 			: integer range 1 to 255	:= 8;
            Enable_Port 	: boolean					:= TRUE);
    Port (  CLK 			: in STD_LOGIC;
            EN	 			: in STD_LOGIC;
			DATA 			: in STD_LOGIC_VECTOR (Width - 1 downto 0);
			ADDRESS			: in STD_LOGIC_VECTOR (clogb2(Max_Latency) - 1 downto 0); 
			DOUT			: out STD_LOGIC_VECTOR (Width - 1 downto 0));
end G_ADDSHIFTREG;

architecture RTL of G_ADDSHIFTREG is
type t_pipe is array(0 to Max_Latency -1) of std_logic_vector(Width-1 downto 0);
signal Enable_inside: STD_LOGIC 							:= '1';
signal pipe_reg 	: t_pipe;  -- Pipelines for latency
signal pipe_out		: STD_LOGIC_VECTOR (Width - 1 downto 0);

begin
    
    if_NE: if(Enable_Port = FALSE) generate     
        Enable_inside <= '1';
	end generate if_NE;
	if_E: if(Enable_Port = TRUE) generate
        Enable_inside <= EN;
    end generate if_E;
	-- Output data goes to first stage of latency pipe
	pr_pipe_in:process(CLK)									
	begin									          
		if(rising_edge(CLK)) then
			if(Enable_inside = '1' ) then
				pipe_reg(0) <= DATA;
			end if;
		end if;
	end process pr_pipe_in;
	-- Output data goes through pipe
	pr_pipe:process(CLK)									
	begin										
		if(rising_edge(CLK)) then
			if(Enable_inside = '1' ) then
                pipe_reg(1 to Max_Latency-1) <= pipe_reg(0 to Max_Latency-2);
			end if;
			
		end if;
	end process pr_pipe;
		
	DOUT <= pipe_reg(To_integer(Unsigned(ADDRESS)));

end RTL;
