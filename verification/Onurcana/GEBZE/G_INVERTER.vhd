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

entity G_INVERTER is
    Generic( Port_Width 	: integer range 1 to 256	:= 32;
			 Latency		: integer range 0 to 256	:= 3;
             Enable_Port 	: boolean					:= FALSE);
    Port ( CLK			    : in STD_LOGIC;
           EN				: in STD_LOGIC;
		   A_SIG 			: in STD_LOGIC_VECTOR (Port_Width - 1 downto 0);
           NOTA 			: out STD_LOGIC_VECTOR (Port_Width - 1 downto 0));
end G_INVERTER;

architecture RTL of G_INVERTER is

type t_pipe is array(0 to Latency -1) of std_logic_vector(Port_Width-1 downto 0);
signal Enable_inside: STD_LOGIC := '1';
signal pre_notA		: STD_LOGIC_VECTOR (Port_Width - 1 downto 0);
signal pipe_reg 	: t_pipe;  -- Pipelines for latency
signal pipe_out		: STD_LOGIC_VECTOR (Port_Width - 1 downto 0);
begin

	if_NE: if(Enable_Port = FALSE) generate     
		Enable_inside <= '1';
	end generate if_NE;
	if_E: if(Enable_Port = TRUE) generate      
		Enable_inside <= EN;
	end generate if_E;
	
	pre_notA <= not A_SIG;
	
	No_Latency: if(Latency = 0) generate
        NOTA <= pre_notA;
    end generate No_Latency;
    
    Lat: if(Latency > 0) generate									-- Output data goes to first stage of latency pipe
        pr_pipe_in:process(CLK)									
        begin									          
            if(CLK'event and CLK = '1') then
                if(Enable_inside = '1' ) then
                    pipe_reg(0) <= pre_notA;
                end if;
            end if;
        end process pr_pipe_in;
    end generate Lat;
    
    Lat_1: if(Latency = 1) generate
           NOTA <= pipe_reg(0);
    end generate Lat_1; 

    Lat_out: if(Latency > 1) generate									-- Output data goes through pipe
        pr_pipe:process(CLK)									
        begin										
          if(CLK'event and CLK = '1') then
            for i in 0 to Latency-2 loop
                pipe_reg(i+1) <= pipe_reg(i);
            end loop;
          end if;
        end process pr_pipe;
        NOTA <= pipe_reg(Latency-1);
    end generate Lat_out;
end RTL;
