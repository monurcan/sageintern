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

entity G_MULTIPLIERUS is
    Generic(AWidth 			: integer range 0 to 256	:= 1;
			BWidth			: integer range 0 to 256	:= 4;
            Enable_Port 	: boolean					:= FALSE);
    Port (  EN	 			: in STD_LOGIC;
			A_SIG 			: in STD_LOGIC_VECTOR (AWidth - 1 downto 0);
			B_SIG 			: in STD_LOGIC_VECTOR (BWidth - 1 downto 0);
            AXB		 		: out STD_LOGIC_VECTOR (AWidth + BWidth - 1 downto 0));
end G_MULTIPLIERUS;

architecture RTL of G_MULTIPLIERUS is

begin
    
	AXB <= std_logic_vector(Unsigned(A_SIG)* Unsigned(B_SIG));
	
end RTL;
