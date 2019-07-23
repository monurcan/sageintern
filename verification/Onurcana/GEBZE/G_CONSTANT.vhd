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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;



entity G_CONSTANT is
    Generic(Value_Width : integer range 1 to 256:= 8;
            Constant_Value : integer:= 0);
    Port ( CONSTANT_OUT : out STD_LOGIC_VECTOR (Value_Width - 1 downto 0));
end G_CONSTANT;

architecture RTL of G_CONSTANT is

begin
    CONSTANT_OUT <= std_logic_vector(To_signed(Constant_Value, Value_Width));
end RTL;
