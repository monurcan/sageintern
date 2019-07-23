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

entity G_CMULTLUT is
    Generic(
			Constant_Value	: integer range -255 to 255	:= 2;
			Signed_Unsigned : boolean					:= FALSE;
			AWidth 			: integer range 2 to 256	:= 8;
            Reset_Port 		: boolean					:= FALSE;
            Enable_Port 	: boolean					:= FALSE;
			Latency		    : integer range 0 to 256	:= 0);
    Port (  CLK 			: in STD_LOGIC;
            RST 			: in STD_LOGIC;
            EN	 			: in STD_LOGIC;
			A_SIG 			: in STD_LOGIC_VECTOR (AWidth - 1 downto 0);
            P_SIG		 	: out STD_LOGIC_VECTOR (AWidth + clogb2(Constant_Value) - 1 downto 0));
end G_CMULTLUT;

architecture RTL of G_CMULTLUT is
type t_pipe is array(0 to Latency -1) of std_logic_vector(P_SIG'HIGH downto 0);
signal result			: unsigned(P_SIG'HIGH downto 0);
signal shifted			: unsigned(P_SIG'HIGH downto 0);
signal shifted_b		: unsigned(P_SIG'HIGH + 1 downto 0);
signal temp				: unsigned(P_SIG'HIGH + 1 downto 0);
signal Enable_inside	: STD_LOGIC := '1';
signal pipe_reg         : t_pipe;  -- Pipelines for Memory

begin

if_NE: if(Enable_Port = FALSE) generate     
    Enable_inside <= '1';
end generate if_NE;
if_E: if(Enable_Port = TRUE) generate      
    Enable_inside <= EN;
end generate if_E;

if_0: if(Constant_Value = 0) generate
	result <= (others => '0');
end generate;

if_1: if(Constant_Value = 1) generate
	result <= unsigned(A_SIG);
end generate;

if_2: if(Constant_Value = 2) generate
	shifted <= unsigned(A_SIG) & '0';
	result  <= shifted;
end generate;

if_3: if(Constant_Value = 3) generate
	shifted <= unsigned(A_SIG) & '0';
	result  <= shifted + unsigned(A_SIG);
end generate;

if_4: if(Constant_Value = 4) generate
	shifted <= unsigned(A_SIG) & "00";
	result  <= shifted;
end generate;

if_5: if(Constant_Value = 5) generate
	shifted <= unsigned(A_SIG) & "00";
	result  <= shifted + unsigned(A_SIG);
end generate;

if_6: if(Constant_Value = 6) generate
	shifted   <= unsigned(A_SIG) & "00";
	shifted_b <= "00" & unsigned(A_SIG) & '0';
	temp      <= shifted_b + shifted;
    result    <= temp(P_SIG'HIGH downto 0);
end generate;

if_7: if(Constant_Value = 7) generate
	shifted_b <= unsigned(A_SIG) & "000";
	temp  <= shifted_b - unsigned(A_SIG);
	result <= temp(P_SIG'HIGH downto 0);
end generate;

if_8: if(Constant_Value = 8) generate
	result <= unsigned(A_SIG) & "000";
end generate;

if_9: if(Constant_Value = 9) generate
	shifted <= unsigned(A_SIG) & "000";
	result  <= shifted + unsigned(A_SIG);
end generate;

if_10: if(Constant_Value = 10) generate
	shifted   <= unsigned(A_SIG) & "000";
	shifted_b <= "000" & unsigned(A_SIG) & '0';
	temp      <= shifted_b + shifted;
    result    <= temp(P_SIG'HIGH downto 0);
end generate;

if_12: if(Constant_Value = 12) generate
	shifted   <= unsigned(A_SIG) & "000";
	shifted_b <= "00" & unsigned(A_SIG) & "00";
	temp      <= shifted_b + shifted;
    result    <= temp(P_SIG'HIGH downto 0);
end generate;

if_14: if(Constant_Value = 14) generate
	shifted_b <= unsigned(A_SIG) & "0000";
	shifted   <= "00" & unsigned(A_SIG) & '0';
	temp      <= shifted_b - shifted;
	result    <= temp(P_SIG'HIGH downto 0);
end generate;

if_15: if(Constant_Value = 15) generate
	shifted_b <= unsigned(A_SIG) & "0000";
	temp      <= shifted_b - unsigned(A_SIG);
	result    <= temp(P_SIG'HIGH downto 0);
end generate;

if_16: if(Constant_Value = 16) generate
	result <= unsigned(A_SIG) & "0000";
end generate;

if_17: if(Constant_Value = 17) generate
	shifted <= unsigned(A_SIG) & "0000";
	result  <= shifted + unsigned(A_SIG);
end generate;

if_18: if(Constant_Value = 18) generate
	shifted   <= unsigned(A_SIG) & "0000";
    shifted_b <= "0000" & unsigned(A_SIG) & '0';
    temp      <= shifted_b + shifted;
    result    <= temp(P_SIG'HIGH downto 0);
end generate;

if_20: if(Constant_Value = 20) generate
	shifted   <= unsigned(A_SIG) & "0000";
    shifted_b <= "000" & unsigned(A_SIG) & "00";
    temp      <= shifted_b + shifted;
    result    <= temp(P_SIG'HIGH downto 0);
end generate;

if_24: if(Constant_Value = 24) generate
	shifted   <= unsigned(A_SIG) & "0000";
    shifted_b <= "00" & unsigned(A_SIG) & "000";
    temp      <= shifted_b + shifted;
    result    <= temp(P_SIG'HIGH downto 0);
end generate;

if_28: if(Constant_Value = 28) generate
	shifted_b <= unsigned(A_SIG) & "00000";
	shifted   <= "00" & unsigned(A_SIG) & "00";
	temp      <= shifted_b - shifted;
	result    <= temp(P_SIG'HIGH downto 0);
end generate;

if_30: if(Constant_Value = 30) generate
	shifted_b <= unsigned(A_SIG) & "00000";
	shifted   <= "000" & unsigned(A_SIG) & '0';
	temp      <= shifted_b - shifted;
	result    <= temp(P_SIG'HIGH downto 0);
end generate;

if_31: if(Constant_Value = 31) generate
	shifted_b <= unsigned(A_SIG) & "00000";
	temp      <= shifted_b - unsigned(A_SIG);
	result    <= temp(P_SIG'HIGH downto 0);
end generate;

if_32: if(Constant_Value = 32) generate
	result <= unsigned(A_SIG) & "00000";
end generate;

if_33: if(Constant_Value = 33) generate
	shifted <= unsigned(A_SIG) & "00000";
	result  <= shifted + unsigned(A_SIG);
end generate;

if_34: if(Constant_Value = 34) generate
	shifted   <= unsigned(A_SIG) & "00000";
	shifted_b <= "00000" & unsigned(A_SIG) & '0';
	temp      <= shifted_b + shifted;
    result    <= temp(P_SIG'HIGH downto 0);
end generate;

if_36: if(Constant_Value = 36) generate
	shifted   <= unsigned(A_SIG) & "00000";
	shifted_b <= "0000" & unsigned(A_SIG) & "00";
	temp      <= shifted_b + shifted;
    result    <= temp(P_SIG'HIGH downto 0);
end generate;

if_40: if(Constant_Value = 40) generate
	shifted   <= unsigned(A_SIG) & "00000";
	shifted_b <= "000" & unsigned(A_SIG) & "000";
	temp      <= shifted_b + shifted;
    result    <= temp(P_SIG'HIGH downto 0);
end generate;

if_48: if(Constant_Value = 48) generate
	shifted   <= unsigned(A_SIG) & "00000";
	shifted_b <= "00" & unsigned(A_SIG) & "0000";
	temp      <= shifted_b + shifted;
    result    <= temp(P_SIG'HIGH downto 0);
end generate;

if_56: if(Constant_Value = 56) generate
	shifted_b <= unsigned(A_SIG) & "000000";
	shifted   <= "00" & unsigned(A_SIG) & "000";
	temp      <= shifted_b - shifted;
	result    <= temp(P_SIG'HIGH downto 0);
end generate;

if_60: if(Constant_Value = 60) generate
	shifted_b <= unsigned(A_SIG) & "000000";
	shifted   <= "000" & unsigned(A_SIG) & "00";
	temp      <= shifted_b - shifted;
	result    <= temp(P_SIG'HIGH downto 0);
end generate;

if_62: if(Constant_Value = 62) generate
	shifted_b <= unsigned(A_SIG) & "000000";
	shifted   <= "0000" & unsigned(A_SIG) & "0";
	temp      <= shifted_b - shifted;
	result    <= temp(P_SIG'HIGH downto 0);
end generate;

if_63: if(Constant_Value = 63) generate
	shifted_b <= unsigned(A_SIG) & "000000";
	shifted   <= "00000" & unsigned(A_SIG);
	temp      <= shifted_b - shifted;
	result    <= temp(P_SIG'HIGH downto 0);
end generate;

if_64: if(Constant_Value = 64) generate
	result <= unsigned(A_SIG) & "000000";
end generate;

if_65: if(Constant_Value = 65) generate
	shifted <= unsigned(A_SIG) & "000000";
	result  <= shifted + unsigned(A_SIG);
end generate;

if_66: if(Constant_Value = 66) generate
	shifted   <= unsigned(A_SIG) & "000000";
	shifted_b <= "000000" & unsigned(A_SIG) & '0';
	temp      <= shifted_b + shifted;
    result    <= temp(P_SIG'HIGH downto 0);
end generate;

if_68: if(Constant_Value = 68) generate
	shifted   <= unsigned(A_SIG) & "000000";
	shifted_b <= "00000" & unsigned(A_SIG) & "00";
	temp      <= shifted_b + shifted;
    result    <= temp(P_SIG'HIGH downto 0);
end generate;

if_72: if(Constant_Value = 72) generate
	shifted   <= unsigned(A_SIG) & "000000";
	shifted_b <= "0000" & unsigned(A_SIG) & "000";
	temp      <= shifted_b + shifted;
    result    <= temp(P_SIG'HIGH downto 0);
end generate;

if_80: if(Constant_Value = 80) generate
	shifted   <= unsigned(A_SIG) & "000000";
	shifted_b <= "000" & unsigned(A_SIG) & "0000";
	temp      <= shifted_b + shifted;
    result    <= temp(P_SIG'HIGH downto 0);
end generate;

if_96: if(Constant_Value = 96) generate
	shifted   <= unsigned(A_SIG) & "000000";
	shifted_b <= "00" & unsigned(A_SIG) & "00000";
	temp      <= shifted_b + shifted;
    result    <= temp(P_SIG'HIGH downto 0);
end generate;

if_112: if(Constant_Value = 112) generate
	shifted_b <= unsigned(A_SIG) & "0000000";
	shifted   <= "00" & unsigned(A_SIG) & "0000";
	temp      <= shifted_b - shifted;
	result    <= temp(P_SIG'HIGH downto 0);
end generate;

if_120: if(Constant_Value = 120) generate
	shifted_b <= unsigned(A_SIG) & "0000000";
	shifted   <= "000" & unsigned(A_SIG) & "000";
	temp      <= shifted_b - shifted;
	result    <= temp(P_SIG'HIGH downto 0);
end generate;

if_124: if(Constant_Value = 124) generate
	shifted_b <= unsigned(A_SIG) & "0000000";
	shifted   <= "0000" & unsigned(A_SIG) & "00";
	temp      <= shifted_b - shifted;
	result    <= temp(P_SIG'HIGH downto 0);
end generate;

if_126: if(Constant_Value = 126) generate
	shifted_b <= unsigned(A_SIG) & "0000000";
	shifted   <= "00000" & unsigned(A_SIG) & "0";
	temp      <= shifted_b - shifted;
	result    <= temp(P_SIG'HIGH downto 0);
end generate;

if_127: if(Constant_Value = 127) generate
	shifted_b <= unsigned(A_SIG) & "0000000";
	shifted   <= "000000" & unsigned(A_SIG);
	temp      <= shifted_b - shifted;
	result    <= temp(P_SIG'HIGH downto 0);
end generate;

if_128: if(Constant_Value = 128) generate
	result <= unsigned(A_SIG) & "0000000";
end generate;

No_Latency: if(Latency = 0) generate
	P_SIG <= std_logic_vector(result);
end generate No_Latency;

Lat: if(Latency > 0) generate									-- Output data goes to first stage of latency pipe
	pr_pipe_in:process(CLK)									
	begin									          
		if(CLK'event and CLK = '1') then
			if(Enable_Inside = '1') then
				pipe_reg(0) <= std_logic_vector(result);
			end if;
		end if;
	end process pr_pipe_in;
end generate Lat;

Lat_1: if(Latency = 1) generate
	   P_SIG <= pipe_reg(0);
end generate Lat_1; 

Lat_out: if(Latency > 1) generate									-- Output data goes through pipe
	pr_pipe:process(CLK)									
	begin										
		if(CLK'event and CLK = '1') then
			if(Enable_Inside = '1') then
					pipe_reg(1 to Latency-1) <= pipe_reg(0 to Latency-2);
			end if;
		end if;
	end process pr_pipe;
	P_SIG <= pipe_reg(Latency-1);
end generate Lat_out;
end RTL;
