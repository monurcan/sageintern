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

entity G_MUX is
    Generic( Input_Width 	: integer range 1 to 256	:= 4;
			 Input_Ports	: integer range 0 to 256	:= 8;
             Enable_Port 	: boolean					:= FALSE;
			 Latency		: integer range 0 to 256	:= 0);
    Port ( CLK			    : in STD_LOGIC;
           EN				: in STD_LOGIC;
		   SEL				: in STD_LOGIC_VECTOR (clogb2(Input_Ports)-1 downto 0);    
		   SIGNALS 			: in STD_LOGIC_VECTOR (Input_Width*Input_Ports - 1 downto 0);
           MUXOUT 			: out STD_LOGIC_VECTOR (Input_Width - 1 downto 0));
end G_MUX;

architecture RTL of G_MUX is

type t_pipe is array(0 to Latency -1) of std_logic_vector(Input_Width-1 downto 0);
type t_slv_array is array (0 to Input_Ports -1) of std_logic_vector(Input_Width-1 downto 0);
signal inp_array    : t_slv_array;
signal Enable_inside: STD_LOGIC := '1';
signal pre_Muxout	: STD_LOGIC_VECTOR (Input_Width - 1 downto 0);
signal pipe_reg 	: t_pipe;  -- Pipelines for latency
signal pipe_out		: STD_LOGIC_VECTOR (Input_Width - 1 downto 0);
begin

	if_NE: if(Enable_Port = FALSE) generate     
		Enable_inside <= '1';
	end generate if_NE;
	if_E: if(Enable_Port = TRUE) generate      
		Enable_inside <= EN;
	end generate if_E;
	
    Mapping:
    for variable_i in 0 to Input_Ports-1 generate
    begin
        inp_array(Input_Ports - 1 - variable_i)  <= 
		SIGNALS((variable_i + 1)*Input_Width -1 downto variable_i*Input_Width);
    end generate;
    
	pre_Muxout <= inp_array(To_integer(Unsigned(SEL)));
	
	No_Latency: if(Latency = 0) generate
        MUXOUT <= pre_Muxout;
    end generate No_Latency;
    
    Lat: if(Latency > 0) generate									-- Output data goes to first stage of latency pipe
        pr_pipe_in:process(CLK)									
        begin									          
            if(CLK'event and CLK = '1') then
                if(Enable_inside = '1' ) then
                    pipe_reg(0) <= pre_Muxout;
                end if;
            end if;
        end process pr_pipe_in;
    end generate Lat;
    
    Lat_1: if(Latency = 1) generate
           MUXOUT <= pipe_reg(0);
    end generate Lat_1; 

    Lat_out: if(Latency > 1) generate									-- Output data goes through pipe
        pr_pipe:process(CLK)									
        begin										
          if(CLK'event and CLK = '1') then
                pipe_reg(1 to Latency-1) <= pipe_reg(0 to Latency-2);
          end if;
        end process pr_pipe;
        MUXOUT <= pipe_reg(Latency-1);
    end generate Lat_out;
end RTL;
