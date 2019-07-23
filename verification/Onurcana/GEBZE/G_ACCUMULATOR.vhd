------------------------------------------------------------------------------------
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
------------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity G_ACCUMULATOR is
    Generic(
            Operation 		: boolean					:= FALSE;
            Width 			: integer range 1 to 256	:= 32;
			Signed_Unsigned : boolean					:= FALSE;
            Reset_Port 		: boolean					:= TRUE;
            Reset_Bypass	: boolean					:= FALSE;
			Latency			: integer range 1 to 256	:= 4;
            Enable_Port 	: boolean					:= TRUE);
    Port (  CLK 			: in STD_LOGIC;
            RST 			: in STD_LOGIC;
            EN	 			: in STD_LOGIC;
			B_SIG 			: in STD_LOGIC_VECTOR (Width - 1 downto 0);
            ACC_OUT 		: out STD_LOGIC_VECTOR (Width - 1 downto 0));
end G_ACCUMULATOR;

architecture RTL of G_ACCUMULATOR is
signal acc_reg	: STD_LOGIC_VECTOR (Width - 1 downto 0)	:= (others => '0');
signal Bypass	: STD_LOGIC_VECTOR (Width - 1 downto 0)	:= (others => '0');
signal Reset	: STD_LOGIC 							:= '0';

type t_pipe is array(0 to Latency -1) of std_logic_vector(Width-1 downto 0);
signal Enable_inside: STD_LOGIC := '1';
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
    
    if_NP: if(Reset_Bypass = FALSE) generate     
        Bypass <= (others => '0');
	end generate if_NP;
	if_P: if(Reset_Bypass = TRUE) generate     
        Bypass <= B_SIG;
    end generate if_P;
    
    if_U:if(Signed_Unsigned = FALSE) generate
		if_0: if(Operation = FALSE) generate       -- Add
			pr_add:process(CLK)
			begin
				if(rising_edge(CLK)) then
					if(Reset = '1') then
						acc_reg <= Bypass;
					elsif(Enable_inside = '1' ) then
						acc_reg <= std_logic_vector(unsigned(acc_reg) + unsigned(B_SIG));
					end if;
				end if;
			end process pr_add;
		end generate if_0;
		
		if_1: if(Operation = TRUE) generate       --Substract
			pr_sub:process(CLK)
			begin
				if(rising_edge(CLK)) then
					if(Reset = '1') then
						acc_reg <= Bypass;
					elsif(Enable_inside = '1' ) then
						acc_reg <= std_logic_vector(unsigned(acc_reg) - unsigned(B_SIG));
					end if;
				end if;
			end process pr_sub;
		end generate if_1;
	end generate if_U;
    
	if_S:if(Signed_Unsigned = TRUE) generate
		if_S0: if(Operation = FALSE) generate       -- Add
			pr_add:process(CLK)
			begin
				if(rising_edge(CLK)) then
					if(Reset = '1') then
						acc_reg <= Bypass;
					elsif(Enable_inside = '1' ) then
						acc_reg <= std_logic_vector(signed(acc_reg) + signed(B_SIG));
					end if;
				end if;
			end process pr_add;
		end generate if_S0;
		
		if_S1: if(Operation = TRUE) generate       --Substract
			pr_sub:process(CLK)
			begin
				if(rising_edge(CLK)) then
					if(Reset = '1') then
						acc_reg <= Bypass;
					elsif(Enable_inside = '1' ) then
						acc_reg <= std_logic_vector(signed(acc_reg) - signed(B_SIG));
					end if;
				end if;
			end process pr_sub;
		end generate if_S1;
	end generate if_S;
		
	No_Latency: if(Latency = 1) generate
        ACC_OUT <= acc_reg;
    end generate No_Latency;
    
    Lat: if(Latency > 1) generate									-- Output data goes to first stage of latency pipe
        pr_pipe_in:process(CLK)									
        begin									          
            if(CLK'event and CLK = '1') then
                if(Enable_inside = '1' ) then
                    pipe_reg(0) <= acc_reg;
                end if;
            end if;
        end process pr_pipe_in;
    end generate Lat;
    
    Lat_1: if(Latency = 2) generate
           ACC_OUT <= pipe_reg(0);
    end generate Lat_1; 

    Lat_out: if(Latency > 2) generate									-- Output data goes through pipe
        pr_pipe:process(CLK)									
        begin										
          if(CLK'event and CLK = '1') then
                pipe_reg(1 to Latency-2) <= pipe_reg(0 to Latency-3);
          end if;
        end process pr_pipe;
        ACC_OUT <= pipe_reg(Latency-2);
    end generate Lat_out;
end RTL;
