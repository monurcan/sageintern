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

entity G_REGISTER is
    Generic(
			Width 			: integer range 1 to 256			 := 8;
			Initial_Value	: integer                            := 0;
            Reset_Port 		: boolean							 := TRUE;
            Enable_Port 	: boolean							 := TRUE);
    Port (  CLK 			: in STD_LOGIC;
            RST 			: in STD_LOGIC;
            EN	 			: in STD_LOGIC;
			DATA 			: in STD_LOGIC_VECTOR (Width - 1 downto 0);
            DOUT		 	: out STD_LOGIC_VECTOR (Width - 1 downto 0));
end G_REGISTER;

architecture RTL of G_REGISTER is
signal Enable_inside	: STD_LOGIC := '1';
signal Reset			: STD_LOGIC := '0';
signal reg_data			: STD_LOGIC_VECTOR (Width - 1 downto 0):= std_logic_vector(To_Signed(Initial_value, Width));
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

pr_reg:process(CLK)									
begin									          
    if(rising_edge(CLK)) then
        if(Reset = '1') then
            reg_data <= std_logic_vector(To_Signed(Initial_value, Width));
        elsif(Enable_Inside = '1') then
            reg_data <= DATA;
        end if;
    end if;
end process pr_reg;

DOUT <= reg_data;
end RTL;
