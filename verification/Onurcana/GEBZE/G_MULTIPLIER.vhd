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

entity G_MULTIPLIER is
    Generic(AWidth 			: integer range 0 to 256	:= 2;
			BWidth			: integer range 0 to 256	:= 2;
			Signed_Unsigned : boolean					:= FALSE;
            Enable_Port 	: boolean					:= TRUE;
            Latency		    : integer range 0 to 256	:= 3);
    Port (  CLK			    : in STD_LOGIC;
			EN	 			: in STD_LOGIC;
			A_SIG 			: in STD_LOGIC_VECTOR (AWidth - 1 downto 0);
			B_SIG 			: in STD_LOGIC_VECTOR (BWidth - 1 downto 0);
            AXB		 		: out STD_LOGIC_VECTOR (AWidth + BWidth - 1 downto 0));
end G_MULTIPLIER;

architecture RTL of G_MULTIPLIER is
type t_pipe is array(0 to Latency -1) of std_logic_vector(AXB'HIGH downto 0);
signal Enable_inside: STD_LOGIC := '1';
signal pre_AXB		: STD_LOGIC_VECTOR (AXB'HIGH downto 0);
signal pipe_reg 	: t_pipe;  -- Pipelines for latency
signal pipe_out		: STD_LOGIC_VECTOR (AXB'HIGH downto 0);
begin

	if_NE: if(Enable_Port = FALSE) generate     
		Enable_inside <= '1';
	end generate if_NE;
	if_E: if(Enable_Port = TRUE) generate      
		Enable_inside <= EN;
	end generate if_E;

    if_U:if(Signed_Unsigned = FALSE) generate
	pre_AXB <= std_logic_vector(Unsigned(A_SIG)* Unsigned(B_SIG));
	end generate if_U;
	
	if_S:if(Signed_Unsigned = TRUE) generate
    pre_AXB <= std_logic_vector(Signed(A_SIG)* Signed(B_SIG));
    end generate if_S;
    
    No_Latency: if(Latency = 0) generate
        AXB <= pre_AXB;
    end generate No_Latency;
    
    Lat: if(Latency > 0) generate        	-- Output data goes to first stage of latency pipe
        pr_pipe_in:process(CLK)                                    
        begin                                              
            if(CLK'event and CLK = '1') then
                if(Enable_inside = '1' ) then
                    pipe_reg(0) <= pre_AXB;
                end if;
            end if;
        end process pr_pipe_in;
    end generate Lat;
    
    Lat_1: if(Latency = 1) generate
           AXB <= pipe_reg(0);
    end generate Lat_1; 

    Lat_out: if(Latency > 1) generate                                    -- Output data goes through pipe
        pr_pipe:process(CLK)                                    
        begin                                        
          if(CLK'event and CLK = '1') then
                pipe_reg(1 to Latency-1) <= pipe_reg(0 to Latency-2);
          end if;
        end process pr_pipe;
        AXB <= pipe_reg(Latency-1);
    end generate Lat_out;
	
end RTL;
