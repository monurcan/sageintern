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



entity G_SLICE is
    Generic(
            Input_Width			: natural:= 8;
            Specify_range_as	: integer:= 0;
            Slice_Width			: natural:= 8;
            High_Bit 			: natural:= 7;
            Low_Bit  			: natural:= 0);
    Port ( A_SIG : in STD_LOGIC_VECTOR(Input_Width - 1 downto 0);
           SLICE : out STD_LOGIC_VECTOR(Slice_Width - 1 downto 0));
end G_SLICE;

architecture RTL of G_SLICE is

begin
    
    if_1: if(Specify_range_as = 0) generate     --Two bit locations
        Slice <= A_SIG (High_Bit downto Low_Bit);
    end generate;
    
    if_2: if(Specify_range_as = 1) generate
        Slice <= A_SIG (High_Bit downto High_Bit - Slice_Width -1); --Upper bit location + width
    end generate;
    
    if_3: if(Specify_range_as = 3) generate
        Slice <= A_SIG (Low_Bit + Slice_Width -1 downto Low_Bit);  --Lower bit location + width
    end generate;

end RTL;
