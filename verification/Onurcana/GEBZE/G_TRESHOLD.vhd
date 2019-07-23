----------------------------------------------------------------------------------
-- Company: TUBITAK SAGE
-- Engineer: Adem GUNESEN
-- 
-- Create Date: 01.04.2019 16:07:19
-- Design Name: Relational
-- Module Name: G_TRESHOLD - RTL
-- Project Name: Relational
-- Target Devices: Unconstrained
-- Tool Versions: Vivado 2016.3
-- Description: A generic relational logic implementation based on System Generator Relational block
--              for A=B, A!=B, A>B, A<B, A>=B, A<=B conditions.
--              Output SIGN = 1 if the specified condition holds.
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


entity G_TRESHOLD is
    Generic(
            Input_Width 	: integer range 0 to 256:= 8;
            Enable_Port 	: boolean 				:= TRUE;
			Latency			: integer range 0 to 256:= 1);
    Port (  CLK 			: in STD_LOGIC;
			EN   			: in STD_LOGIC;
			A_SIG       	: in STD_LOGIC_VECTOR (Input_Width - 1 downto 0);
            SIGN	       	: out STD_LOGIC_VECTOR(1 downto 0));
end G_TRESHOLD;

architecture RTL of G_TRESHOLD is
	type t_pipe is array(0 to Latency -1) of std_logic_vector(1 downto 0);
    signal temp 			: std_logic_vector(1 downto 0) := "01";
	signal Enable_inside	: STD_LOGIC := '1';
	signal pipe_reg 		: t_pipe;
	signal pipe_out			: STD_LOGIC_VECTOR (1 downto 0);
	constant C_Pos_One		: std_logic_vector(1 downto 0) := "01";
	constant C_Neg_One		: std_logic_vector(1 downto 0) := "11";
begin

	if_NE: if(Enable_Port = FALSE) generate     
		Enable_inside <= '1';
	end generate if_NE;
	if_E: if(Enable_Port = TRUE) generate      
		Enable_inside <= EN;
	end generate if_E;
	
	temp <= C_Neg_One when A_SIG(Input_Width - 1) = '1' else C_Pos_One;

	No_Latency: if(Latency = 0) generate
        SIGN <= temp;
    end generate No_Latency;
    
    Lat: if(Latency > 0) generate									-- Output data goes to first stage of latency pipe
        pr_pipe_in:process(CLK)									
        begin									          
            if(CLK'event and CLK = '1') then
                if(Enable_inside = '1' ) then
                    pipe_reg(0) <= temp;
                end if;
            end if;
        end process pr_pipe_in;
    end generate Lat;
    
    Lat_1: if(Latency = 1) generate
           SIGN <= pipe_reg(0);
    end generate Lat_1; 

    Lat_Out: if(Latency > 1) generate									-- Output data goes through pipe
        pr_pipe:process(CLK)									
        begin										
          if(CLK'event and CLK = '1') then
                pipe_reg(1 to Latency) <= pipe_reg(0 to Latency-1);
          end if;
        end process pr_pipe;
        SIGN <= pipe_reg(Latency-1);
    end generate Lat_out;

end RTL;
