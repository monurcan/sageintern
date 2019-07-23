--------------------------------------------------------------------------------
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
library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;
package P_SAGE_LIB is	
	function clogb2( 
	depth : integer) return integer;
end package P_SAGE_LIB;

package body P_SAGE_LIB is

	function clogb2( depth : integer) return integer is
	variable v_temp    : integer range 0 to 1073741824:= depth;
	variable v_ret_val : integer range 0 to 1073741824:= 0;
	begin
	  while v_temp > 1 loop
		v_ret_val := v_ret_val + 1;
		v_temp    := v_temp / 2;
	  end loop;
	  if(2**v_ret_val = depth) then
		return v_ret_val;
	  else
		return v_ret_val + 1;
	  end if;
	end function;
end package body P_SAGE_LIB;