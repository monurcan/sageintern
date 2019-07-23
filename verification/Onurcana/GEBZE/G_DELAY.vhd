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

entity G_DELAY is
    Generic(
            Latency		    : integer range 0 to 256	:= 5;
            Width 			: integer range 1 to 256	:= 8;
            Reset_Port 		: boolean					:= TRUE;
            Enable_Port 	: boolean					:= TRUE);
    Port (  CLK 			: in STD_LOGIC;
            RST 			: in STD_LOGIC;
            EN	 			: in STD_LOGIC;
			A_SIG 			: in STD_LOGIC_VECTOR (Width - 1 downto 0);
			DOUT			: out STD_LOGIC_VECTOR (Width - 1 downto 0));
end G_DELAY;

architecture RTL of G_DELAY is
type t_pipe is array(0 to Latency -1) of std_logic_vector(Width-1 downto 0);
signal Reset		: STD_LOGIC 							:= '0';
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
    
    if_NR: if(Reset_Port = FALSE) generate     
        Reset <= '0';
	end generate if_NR;
	if_R: if(Reset_Port = TRUE) generate        
        Reset <= RST;
    end generate if_R;


	No_Latency: if(Latency = 0) generate
        DOUT <= A_SIG;
    end generate No_Latency;
    
    Lat: if(Latency > 0) generate									-- Output data goes to first stage of latency pipe
        pr_pipe_in:process(CLK)									
        begin									          
            if(rising_edge(CLK)) then
				if(Reset = '1') then
					pipe_reg(0) <= (others => '0');
				else
					if(Enable_inside = '1' ) then
						pipe_reg(0) <= A_SIG;
					end if;
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
		  if(rising_edge(CLK)) then
				if(Reset = '1') then
						pipe_reg(1 to Latency-1) <= (others=>(others => '0'));
				elsif(Enable_inside = '1' ) then
						pipe_reg(1 to Latency-1) <= pipe_reg(0 to Latency-2);
				end if;
          end if;
        end process pr_pipe;
        DOUT <= pipe_reg(Latency-1);
    end generate Lat_out;

end RTL;
