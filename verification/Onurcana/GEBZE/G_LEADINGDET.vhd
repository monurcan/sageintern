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

entity G_LEADINGDET is
    Generic( Port_Width 	: integer range 1 to 256	:= 32;
			 Detect_from	: boolean					:= TRUE; --False: LSB,  True: MSB
			 Detect_Value	: boolean					:= TRUE; --False: '0',  True: '1'
			 Latency		: integer range 0 to 256	:= 0;
             Enable_Port 	: boolean					:= FALSE);
    Port ( CLK			    : in STD_LOGIC;
           EN				: in STD_LOGIC;
		   A_SIG 			: in STD_LOGIC_VECTOR (Port_Width - 1 downto 0);
           DETECTED 		: out STD_LOGIC_VECTOR (Port_Width - 1 downto 0));
end G_LEADINGDET;

architecture RTL of G_LEADINGDET is

type t_pipe is array(0 to Latency -1) of std_logic_vector(Port_Width-1 downto 0);
signal Enable_inside: STD_LOGIC := '1';
signal add_1		: STD_LOGIC_VECTOR (Port_Width - 1 downto 0);
signal add_1_r		: STD_LOGIC_VECTOR (Port_Width - 1 downto 0);
signal reverse_A	: STD_LOGIC_VECTOR (Port_Width - 1 downto 0);

signal add_1_n		: STD_LOGIC_VECTOR (Port_Width - 1 downto 0);
signal add_1_r_n	: STD_LOGIC_VECTOR (Port_Width - 1 downto 0);
signal reverse_A_n	: STD_LOGIC_VECTOR (Port_Width - 1 downto 0);

signal pre_detected	: STD_LOGIC_VECTOR (Port_Width - 1 downto 0);
signal pre_detected_r	: STD_LOGIC_VECTOR (Port_Width - 1 downto 0);
signal pipe_reg 	: t_pipe;  -- Pipelines for latency
signal pipe_out		: STD_LOGIC_VECTOR (Port_Width - 1 downto 0);
begin

	if_NE: if(Enable_Port = FALSE) generate     
		Enable_inside <= '1';
	end generate if_NE;
	if_E: if(Enable_Port = TRUE) generate      
		Enable_inside <= EN;
	end generate if_E;
	

	
	if_LSB: if(Detect_from = FALSE) generate 
		if_1: if(Detect_Value = TRUE) generate 
			add_1 <= std_logic_vector(unsigned(not A_SIG) + 1);
			pre_detected <= add_1 and A_SIG;
		end generate if_1;
		
		if_0: if(Detect_Value = FALSE) generate 
			add_1_n <= std_logic_vector(unsigned( A_SIG) + 1);
			pre_detected <= add_1_n and (not A_SIG);
		end generate if_0;
	end generate if_LSB;
	
	if_MSB: if(Detect_from = TRUE) generate 
		if_R1: if(Detect_Value = TRUE) generate 
			reversing: for v_i in 0 to Port_Width - 1 generate
				reverse_A(v_i) <= A_SIG(Port_Width - 1 - v_i);
			end generate;
			add_1_r <= std_logic_vector(unsigned(not reverse_A) + 1);
			pre_detected_r <= add_1_r and reverse_A;
		end generate if_R1;
		
		if_R0: if(Detect_Value = FALSE) generate 
			reversing_n: for v_in in 0 to Port_Width - 1 generate
				reverse_A_n(v_in) <= not A_SIG(Port_Width - 1 - v_in);
			end generate;
			add_1_r_n <= std_logic_vector(unsigned(reverse_A_n) + 1);
			pre_detected_r <= add_1_r_n and reverse_A_n;
		end generate if_R0;
		
		reversing_pre:for v_io in 0 to Port_Width - 1 generate
			pre_detected(v_io) <= pre_detected_r(Port_Width - 1 - v_io);
		end generate;
	end generate if_MSB;
	
	No_Latency: if(Latency = 0) generate
        DETECTED <= pre_detected;
    end generate No_Latency;
    
    Lat: if(Latency > 0) generate									-- Output data goes to first stage of latency pipe
        pr_pipe_in:process(CLK)									
        begin									          
            if(CLK'event and CLK = '1') then
                if(Enable_inside = '1' ) then
                    pipe_reg(0) <= pre_detected;
                end if;
            end if;
        end process pr_pipe_in;
    end generate Lat;
    
    Lat_1: if(Latency = 1) generate
           DETECTED <= pipe_reg(0);
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
        DETECTED <= pipe_reg(Latency-1);
    end generate Lat_out;
end RTL;
